var ArcticDEM = ee.Image("UMN/PGC/ArcticDEM/V2/5m").select("elevation");
var roi = ee.Geometry.Polygon(-148.82211, 69.49305,-148.80658, 69.49731,-148.79748, 69.4943, -148.81585, 69.48874);

print(Planet_Beaded);

var test_image = Planet_Beaded.first();
print(test_image);

var vizParams = {
  bands:['B8','B4','B3'],
  min: 0, 
  max: 5000,
  gamma: [0.95,1.1,1]
};

var mndwi_viz = {min: -2, max: 1, palette: ['000000', 'FFFFFF']};

Map.centerObject(roi, 14);
Map.addLayer(test_image, {bands: ['B4', 'B3', 'B2'], min: 0, max: 3000}, 'Planet');
Map.addLayer(ArcticDEM, {min: 160, max: 180}, 'ArcticDEM');

var mndwi_planet = test_image.normalizedDifference(['B2', 'B4']);

Map.addLayer(mndwi_planet, mndwi_viz, 'MNDWI_Planet');

var threshold_planet = mndwi_planet.lt(-0.5);

Map.addLayer(threshold_planet, {min:0, max:1} , "Threshold_Planet");

var addMNDWI = function(image) {
  var mndwi = image.normalizedDifference(['B2', 'B4']).rename('MNDWI');
  return mndwi;
};

var mndwiVisParams = {
  bands: 'MNDWI', 
  min: -1, 
  max: 0, 
  palette: ['white', 'blue']
};
Map.addLayer(addMNDWI(test_image), mndwiVisParams, 'test MNDWI');

var withMNDWI = Planet_Beaded.map(addMNDWI);
print(withMNDWI);

Map.addLayer(withMNDWI.select('MNDWI'), mndwiVisParams, 'Planet with MNDWI');

Export.image.toDrive({
  image: withMNDWI.first(),
  description: 'Planet_MNDWI_1',
  scale: 3
});

var threshold_planet = mndwi_planet.lt(-0.5);

