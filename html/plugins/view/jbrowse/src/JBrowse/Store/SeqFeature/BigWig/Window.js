define( "JBrowse/Store/SeqFeature/BigWig/Window", [
            'dojo/_base/declare',
            'dojo/_base/lang',
            './RequestWorker'
        ],
        function( declare, lang, RequestWorker ) {

var dlog = function(){ console.log.apply(console, arguments); };

return declare( null,
 /**
  * @lends JBrowse.Store.BigWig.Window.prototype
  */
{

    /**
     * View into a subset of the data in a BigWig file.
     *
     * Adapted by Robert Buels from bigwig.js in the Dalliance Genome
     * Explorer by Thomas Down.
     * @constructs
     */
    constructor: function(bwg, cirTreeOffset, cirTreeLength, isSummary) {
        this.bwg = bwg;
        this.cirTreeOffset = cirTreeOffset;
        this.cirTreeLength = cirTreeLength;
        this.isSummary = isSummary;
    },

    BED_COLOR_REGEXP: /^[0-9]+,[0-9]+,[0-9]+/,

    readWigData: function(chrName, min, max, callback, errorCallback ) {
        // console.log( 'reading wig data from '+chrName+':'+min+'..'+max);
        var chr = this.bwg.refsByName[chrName];
        if ( ! chr ) {
            // Not an error because some .bwgs won't have data for all chromosomes.

            // dlog("Couldn't find chr " + chrName);
            // dlog('Chroms=' + miniJSONify(this.bwg.refsByName));
            callback([]);
        } else {
            this.readWigDataById( chr.id, min, max, callback, errorCallback );
        }
    },

    readWigDataById: function(chr, min, max, callback, errorCallback ) {
        if( !this.cirHeader ) {
            var readCallback = lang.hitch( this, 'readWigDataById', chr, min, max, callback );
            if( this.cirHeaderLoading ) {
                this.cirHeaderLoading.push( readCallback );
            }
            else {
                this.cirHeaderLoading = [ readCallback ];
                // dlog('No CIR yet, fetching');
                this.bwg.data
                    .slice(this.cirTreeOffset, 48)
                    .fetch( lang.hitch( this, function(result) {
                                this.cirHeader = result;
                                var la = new Int32Array( this.cirHeader, 0, 2 );
                                this.cirBlockSize = la[1];
                                dojo.forEach( this.cirHeaderLoading, function(c) { c(); });
                                delete this.cirHeaderLoading;
                            }), errorCallback );
            }
            return;
        }

        //dlog('_readWigDataById', chr, min, max, callback);

        var worker = new RequestWorker( this, chr, min, max, callback, errorCallback );
        worker.cirFobRecur([this.cirTreeOffset + 48], 1);
    }
});

});
