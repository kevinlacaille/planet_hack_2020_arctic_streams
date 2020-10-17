var ArcticDEM = ee.Image("UMN/PGC/ArcticDEM/V2/5m").select("elevation");
var roi = ee.Geometry.Polygon(-148.82211, 69.49305,-148.80658, 69.49731,-148.79748, 69.4943, -148.81585, 69.48874);
var sentinel = ee.ImageCollection('COPERNICUS/S2_SR')//Pulling a useful image from the Sentinel 2
                .filterBounds(geom_point) 
                .filterDate('2019-07-01', '2019-09-01')
                .sort('CLOUDY_PIXEL_PERCENTAGE')
                .first();
var cirViz = {bands: 'B4,B3,B2', min:0, max:[5000,2000,2000]};
// var rgbViz = {bands: 'B1,B2,B3', min:0, max:[2000,2000,2000]};
var rgbViz = {bands: 'B3,B2,B1', min:0, max:[2000,2000,2000]};

print(beaded_Planet);
print(sentinel);
Map.addLayer(beaded_Planet, cirViz, 'planet collection CIR');
Map.addLayer(beaded_Planet, rgbViz, 'planet collection RGB');

var planet = beaded_Planet.first();
print(planet);

var sent_clip = sentinel//.clip(roi);
print(sent_clip);

var vizParams = {
  bands:['B8','B4','B3'],
  min: 0, 
  max: 5000,
  gamma: [0.95,1.1,1]
};

Map.centerObject(geom_point, 14);
Map.addLayer(roi);
Map.addLayer(sent_clip, vizParams, 'Sentinel');
Map.addLayer(planet, {bands: ['B4', 'B3', 'B2'], min: 0, max: 3000}, 'Planet');
Map.addLayer(ArcticDEM, {min: 160, max: 180}, 'ArcticDEM');

var mndwi_planet = planet.normalizedDifference(['B2', 'B4']);
var mndwi_sentinel = sent_clip.normalizedDifference(['B3', 'B8']);

var mndwi_viz = {min: -1, max: 1, palette: ['000000', 'FFFFFF']};

Map.addLayer(mndwi_planet, mndwi_viz, 'MNDWI_Planet');
Map.addLayer(mndwi_sentinel, mndwi_viz, 'MNDWI_Sentinel');

var threshold_planet = mndwi_planet.lt(-0.5);
var threshold_sentinel = mndwi_sentinel.lt(-0.75);

Map.addLayer(threshold_planet, {min:0, max:1} , "Threshold_Planet");
Map.addLayer(threshold_sentinel, {min:0, max:1} , "Threshold_Sentinel");

// Make the training dataset.
var training_sentinel = mndwi_sentinel.sample({
  region: roi,
  scale: 10,
  numPixels: 5000
});

var training_planet_mndwi = mndwi_planet.sample({
  region: roi,
  scale: 3,
  numPixels: 5000
});

var training_planet = planet.sample({
  region: roi,
  scale: 3,
  numPixels: 5000
});

// Instantiate the clusterer and train it.
var clusterer_sentinel = ee.Clusterer.wekaKMeans(5).train(training_sentinel);

var clusterer_planet_mndwi = ee.Clusterer.wekaKMeans(5).train(training_planet_mndwi);

var clusterer_planet = ee.Clusterer.wekaKMeans(5).train(training_planet);


// Cluster the input using the trained clusterer.
var result_sentinel = mndwi_sentinel.cluster(clusterer_sentinel);

var result_planet_mndwi = mndwi_planet.cluster(clusterer_planet_mndwi); 

var result_planet = planet.cluster(clusterer_planet); 

// Display the clusters with random colors.
Map.addLayer(result_sentinel.randomVisualizer(), {}, 'Sentinel MNDWI kmeans');
Map.addLayer(result_planet_mndwi.randomVisualizer(), {}, 'Planet MNDWI kmeans');
Map.addLayer(result_planet.randomVisualizer(), {}, 'Planet kmeans');