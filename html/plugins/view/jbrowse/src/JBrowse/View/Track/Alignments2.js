define( "JBrowse/View/Track/Alignments2", [
            'dojo/_base/declare',
            'dojo/_base/array',
            'JBrowse/Util',
            'JBrowse/View/Track/CanvasFeatures',
            'JBrowse/View/Track/_AlignmentsMixin'
        ],
        function( declare, array, Util, CanvasFeatureTrack, AlignmentsMixin ) {

return declare( [ CanvasFeatureTrack, AlignmentsMixin ], {

    constructor: function() {
    },

    _defaultConfig: function() {
        return Util.deepUpdate(
            dojo.clone( this.inherited(arguments) ),
            {
                glyph: 'JBrowse/View/FeatureGlyph/Alignment',
                maxFeatureGlyphExpansion: 0,
                style: {
                    showLabels: false
                }
            }
        );
    }

});
});