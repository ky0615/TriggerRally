/**
 * @author jareiko / http://www.jareiko.net/
 */

var MODULE = 'track';

(function(exports) {
  var LFIB4 = this.LFIB4 || require('./LFIB4');
  var THREE = this.THREE || require('../THREE');
  var pterrain = this.pterrain || require('./pterrain');

  var Vec3 = THREE.Vector3;
  
  exports.Track = function() {
    this.config = {};
    this.checkpoints = [];
  };

  exports.Track.prototype.loadWithConfig = function(config, callback) {
    this.config = config;
    this.setup();

    if (config.terrain) {
      var terrainConfig = config.terrain;
      if (!config.terrain) {
        // Fallback for older configs.
        terrainConfig = {
          height: {
            url: config.terrain.heightmap,
            scale: [
              config.terrain.horizontalscale,
              config.terrain.horizontalscale,
              config.terrain.verticalscale
            ]
          }
        };
      }

      var source = new pterrain.ImageSource();
      var terrain = new pterrain.Terrain(source);
      this.terrain = terrain;

      source.load(terrainConfig, function() {
        var course = config.course;
        var cpts = course.checkpoints;
        // TODO: Move this change to config.
        course.coordscale[1] *= -1;
        for (i = 0; i < cpts.length; ++i) {
          var checkpoint = new Vec3(
              cpts[i].pos[0] * course.coordscale[0],
              cpts[i].pos[1] * course.coordscale[1],
              -Infinity);
          var contact = this.terrain.getContact(checkpoint);
          checkpoint.z = contact.surfacePos.z + 2;
          this.checkpoints.push(checkpoint);
        }

        this.scenery = new scenery.Scenery(config.scenery, this);

        if (callback) callback();
      }.bind(this));
    }
  };

  exports.Track.prototype.setup = function() {
  };
})(typeof exports === 'undefined' ? this[MODULE] = {} : exports);
