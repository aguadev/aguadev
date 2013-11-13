.. _dojox/data/XmlStore-examples:

=============================
dojox.data.XmlStore examples
=============================

.. contents ::
    :depth: 3

subclassing the XmlStore to use an xml-string instead of an url to an xml-file
-------------------------------------------------------------------------------
by overriding the method _fetchItems its possible to turn off the xhrGet to the url.
the next step is to use the dojox.xml.parser to read the xml string.

.. code-example ::

  .. js ::

        dojo.require("dijit.Tree");
        dojo.require("dijit.tree.TreeStoreModel");
        dojo.require("dojox.data.XmlStore");
        dojo.require("dojox.xml.parser");

        dojo.ready(function(){
            hookXmlStore();

            var myxml = '<?xml version="1.0" encoding="utf-8"?><root><node><description>Node 1 Description</description><node><heading>1</heading><description>Node 2 Description</description><node><heading>1.1.a</heading><description>Node 3 Description</description></node><node><heading>1.1.b</heading><description>Node 4 Description</description></node></node></node></root>';

            var store = new my.data.XmlStringStore({
                xmlstring: myxml,
                label: "description"
            });

            var model = new dijit.tree.TreeStoreModel({
                store: store,
                rootId: "root",
                rootLabel: "root",
                childrenAttrs: ["node"]
            });

            var tree = new dijit.Tree({
                model: model
            }, "tree");
        });


        hookXmlStore = function(){

            dojo.declare("my.data.XmlStringStore", [dojox.data.XmlStore], {
                constructor: function(args){
                    this.inherited("constructor", arguments);

                    this.xmlstring = args.xmlstring;
                    this.url = "dummy.xml";
                },
                _fetchItems: function(request, fetchHandler, errorHandler){
                    var url = this._getFetchUrl(request);

                    if(!url){
                        errorHandler(new Error("No URL specified."));
                        return;
                    }
                    var localRequest = (!this.sendQuery ? request : {});
                    var data = dojox.xml.parser.parse(this.xmlstring);
                    var items = this._getItems(data, localRequest);

                    if(items && items.length > 0){
                        fetchHandler(items, request);
                    }else{
                        fetchHandler([], request);
                    }
                }
            });

        };


  .. html ::

     <div id="tree"></div>
