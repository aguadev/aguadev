dojo.provide("plugins.form.ValidationTextarea");
dojo.require("dijit.form.SimpleTextarea");
dojo.require("dijit.form.ValidationTextBox");

dojo.declare("plugins.form.ValidationTextarea",
    [dijit.form.ValidationTextBox,dijit.form.SimpleTextarea],
    {
        invalidMessage: "This field is required",

        regExp: "(.|\\s)*",

        preamble : function(args)
        {
            //////console.log("plugins.form.ValidationTextarea.preamble    plugins.form.ValidationTextarea.preamble(arguments)");
            //////console.log("plugins.form.ValidationTextarea.preamble    args:" + dojo.toJson(args));
            //////console.log("plugins.form.ValidationTextarea.preamble   this.invalidMessage: " + this.invalidMessage);
            //
            this.invalidMessage = args.invalidMessage;
        },


        constructor : function(args)
        {
            //////console.log("plugins.form.ValidationTextarea.constructor    plugins.form.ValidationTextarea.constructor(arguments)");
            //////console.log("plugins.form.ValidationTextarea.constructor    args:" + dojo.toJson(args));
            //////console.log("plugins.form.ValidationTextarea.constructor   this.invalidMessage: " + this.invalidMessage);
            //
            this.invalidMessage = args.invalidMessage;
            this.promptMessage = args.promptMessage;
        },

        postCreate: function() {
            //////console.log("plugins.form.ValidationTextarea.postCreate    plugins.form.ValidationTextarea.postCreate(arguments)");
            //////console.log("plugins.form.ValidationTextarea.postCreate    arguments:" + dojo.toJson(arguments));
            //////console.log("plugins.form.ValidationTextarea.postCreate    this.invalidMessage: " + this.invalidMessage);
            
            // SAVE INVALID MESSAGE
            var tempInvalidMessage = this.invalidMessage;
            var tempPromptMessage = this.promptMessage;

            this.inherited(arguments);
            
            // RESTORE INVALID MESSAGEA
            this.invalidMessage = tempInvalidMessage;
            this.promptMessage = tempPromptMessage;
            //////console.log("plugins.form.ValidationTextarea.postCreate    this.invalidMessage: " + this.invalidMessage);
        },

        validate: function() {
            //////console.log("plugins.form.ValidationTextarea.validate    plugins.form.ValidationTextarea.validate(arguments)");
            //////console.log("plugins.form.ValidationTextarea.validate    arguments:" + dojo.toJson(arguments));
            //////console.log("plugins.form.ValidationTextarea.validate    this.invalidMessage: " + this.invalidMessage);

            this.inherited(arguments);

            if (arguments.length==0) this.validate(false);
        },

        onFocus: function() {
            if (!this.isValid()) {
                this.displayMessage(this.getErrorMessage());
            }
        },

        onBlur: function() {
            this.validate(false);
        }
     }
);
