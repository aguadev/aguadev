/**
 * Mixin that adds _estimateGlobalStats method to a store, which
 * samples a section of the features in the store and uses those to
 * esimate the statistics of the whole data set.
 */

define("JBrowse/Store/SeqFeature/GlobalStatsEstimationMixin", [
           'dojo/_base/declare',
           'dojo/_base/array',
           'dojo/Deferred'
       ],
       function( declare, array, Deferred ) {

return declare( null, {

    /**
     * Fetch a region of the current reference sequence and use it to
     * estimate the feature density of the store.
     * @private
     */
    _estimateGlobalStats: function() {
        var deferred = new Deferred();

        var statsFromInterval = function( refSeq, length, callback ) {
            var thisB = this;
            var sampleCenter = refSeq.start*0.75 + refSeq.end*0.25;
            var start = Math.max( 0, Math.round( sampleCenter - length/2 ) );
            var end = Math.min( Math.round( sampleCenter + length/2 ), refSeq.end );
            var features = [];
            this._getFeatures({ ref: refSeq.name, start: start, end: end},
                              function( f ) { features.push(f); },
                              function( error ) {
                                  features = array.filter( features, function(f) { return f.get('start') >= start && f.get('end') <= end; } );
                                  callback.call( thisB, length,
                                                 {
                                                     featureDensity: features.length / length,
                                                     _statsSampleFeatures: features.length,
                                                     _statsSampleInterval: { ref: refSeq.name, start: start, end: end, length: length }
                                                 });
                              },
                              function( error ) {
                                      console.error( error );
                                      callback.call( thisB, length,  null, error );
                              });
        };

        var maybeRecordStats = function( interval, stats, error ) {
            if( error ) {
                deferred.reject( error );
            } else {
                var refLen = this.refSeq.end - this.refSeq.start;
                 if( stats._statsSampleFeatures >= 300 || interval * 2 > refLen || error ) {
                     console.log( 'Store statistics: '+(this.source||this.name), stats );
                     deferred.resolve( stats );
                 } else {
                     statsFromInterval.call( this, this.refSeq, interval * 2, maybeRecordStats );
                 }
            }
        };

        statsFromInterval.call( this, this.refSeq, 100, maybeRecordStats );
        return deferred;
    }

});
});