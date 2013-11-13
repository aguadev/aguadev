.. _dojox/editor/plugins/SpellCheck:

====================================================
dojox.editor.plugins.SpellCheck (Under Construction)
====================================================

:Authors: He Gu Yi
:Project owner: Jared Jurkiewicz
:since: V1.6

.. contents ::
    :depth: 2

Have you ever wanted to make sure that your edited content was spelled correctly? You could always have a dictionary available but, otherwise, this plug-in is for you.

Features
========

Once required in and enabled, this plugin provides the following features to dijit.Editor

* Batch spell check that allows the user to step through the content at any time, identifying unrecognized words, allowing the user to

 * choose an alternative spelling
 * skip the unrecognized word
 * skip all instances of the unrecognized word
 * add the word to the dictionary
 * replace the word with a stored spelling
 * replace all instances of the word with a stored spelling.

* Interactive spell check which provides the same features through a context menu on unrecognized words as they are typed.

Usage
=====

Basic Usage
-----------
First, configure the server-side php file.

* Rename **dojox/editor/tests/spellCheck.php.disabled** to **dojox/editor/tests/spellCheck.php**. The php file is used to check a list of given words and return a list with suggested words.
* Rename **dojox/editor/tests/PorterStemmer.php.disabled** to **dojox/editor/tests/PorterStemmer**.

Then in your HTML code, first load the CSS.
Note that the location of SpellCheck.css may be changed according to the actual environment.

.. css ::

    @import "../plugins/resources/css/SpellCheck.css";


Then load the Editor and the plugin:

.. js ::

    dojo.require("dijit.Editor");
    dojo.require("dojox.editor.plugins.SpellCheck");

Finally, declare the Editor to use it:

.. html ::

  <div data-dojo-type="dijit/Editor" id="editor"
      data-dojo-props="extraPlugins:[{name: 'SpellCheck', url: 'spellCheck.php', interactive: true, timeout: 20, bufferLength: 100, lang: 'en'}]">
  ...
  </div>

And that's it. The editor instance you can reference by 'dijit.byId("editor")' is now enabled with the SpellCheck plugin!

Configurable Options
--------------------

========================  =================  ============  =======================  =============================================================================
Argument Name             Data Type          Optional      Default Value            Description
========================  =================  ============  =======================  =============================================================================
name                      String             False         SpellCheck               The name of this plugin. It should always be "spellcheck".
url                       String             False         <empty string>           The url of the speck check service.
interactive               Boolean            True          False                    Indicate if the interactive mode is on. The default value is false.
timeout                   Number             True          30                       Indicate the timeout when waiting for the server's response.
                                                                                    The default value is 30 seconds if not specified.
bufferLength              Number             True          100                      Specify the max character number in the body of a http GET request.
                                                                                    This parameter is used when the server-side has a request size restriction.
<other arguments>         N/A                True          N/A                      Any other argument that will be passed to the server untouched.
                                                                                    For example, lang: 'en', enableDebugging: true, etc.
========================  =================  ============  =======================  =============================================================================

Set up the server
-----------------

The demo php application provided by Dojo SDK consists of three parts: spellCheck.php, PorterStemmer.php and wordlist.txt

* **spellCheck.php** - This php file is used to receive the request words, check them and response with suggested words.
* **PorterStemmer.php** - This php file implements PorterStemmer algorithm to remove the suffixes of English words automatically.
* **wordlist.txt** - This text file contains the words, which is used as a dictionary.

If you want to use this feature in your application, you need to understand the protocol this feature adopts to communicate with the server.

SpellCheck adopts JSONP protocol and uses GET request to send the words that are to be checked. Suppose we have a plugin declaration as follows.

.. html ::

  <div data-dojo-type="dijit/Editor" id="editor" data-dojo-props="extraPlugins:[{name: 'SpellCheck', url: 'spellCheck.php', interactive: true, timeout: 20, bufferLength: 100, lang: 'en'}]">

The request may look like the following:

.. html ::

  GET spellCheck.php?lang=EN&action=query&content=the%20is%20a%20demo%20to%20show%20how%20use%20spell%20check%20plugin%20you%20need%20php%20server%20test%20this%20please%20enable%20dojox%20editor&callback=dojo.io.script.jsonp_dojoIoScript1._jsonpCallback

We have three parameters in the request: content, callback and lang.

* **content** - The word list to be checked. The words are divided by space char. It may look like "thi is an errir".
* **callback** - This one is the name of callback function. For more information, please refer to JSONP specification.
* **lang** - This parameter is specified by the user. It could be any parameter here as long as it is declared in the plugin declaration.

What the server-side piece response should follow the format below:

.. js ::

  callbackName(
    response:[
      {text: "word1", suggestion: ["w11", "w12"]},
      {text: "word2", suggestion: ["w21", "w22"]},
      ...
    ]
  );

The callbackName gets from the "callback" parameter in the request. And you should not rename "response", "text" and "suggestion" in the template to other words. The response may look like the following.

.. js ::

  dojo.io.script.jsonp_dojoIoScript1._jsonpCallback({response:[{"text":"spellcheck","suggestion":[]},{"text":"porterstemmer","suggestion":[]},{"text":"i","suggestion":[]},{"text":"errir","suggestion":["terror"]},{"text":"thi","suggestion":["hit","the","thin","this","tie"]},{"text":"wrng","suggestion":["warn","wrong"]},{"text":"txt","suggestion":["tax"]}]});

User Interface
==============

Batch Spell Check
-----------------

Click the **Batch Spell Check** button to open the dialog. SpellCheck will highlight all the unrecognized words and the first unrecognized word will be selected and shown in the **Not found** text field.

.. image :: BatchSpellCheck.png

Skip
----

There are two ways to ignore the word in the **Not found** text field and move to the next word. The ignored word will be considered recognized as long as the editor is not destroyed.

* Click the **Skip** button.
* Or type **Enter** in the **Not found** text field.

.. image :: Skip.png

Skip All
--------

**Skip All** to ignore the word displayed in the **Not found** text field and all similarly spelled words. All the similarly spelled words will be considered recognized as long as the editor is not destroyed.

.. image :: SkipAll.png

Add to dictionary
-----------------

Click **Add to dictionary** to add this word into the dictionary. The dictionary is on the server side, which is wordlist.txt in the demo application provided by Dojo SDK. This word will be regarded as a correct one from then on.

.. image :: AddToDictionary.png

Replace
-------

Take either one of the following two actions to address an unrecognized word displayed in the **Not found** text field.

* Select a right one from the **Suggestions** list box.
* Replace it directly in the **Not found** text field.

Then you can type **Enter** in the **Not found** text field or click **Replace** to replace the unrecognized one with the new one and move to the next unrecognized word.

.. image :: Replace.png

Note that when the content of the **Not found** text field is changed, its label will be changed to **Replace with**.

.. image :: ReplaceWith.png

Replace All
-----------

Take either one of the following two actions if the word is unrecognized.

* Select a right one from the **Suggestions** list box.
* Replace it directly in the **Not found** text field.

Then click **Replace All** to replace all the occurrence of this word with the new one and move to the next unrecognized word.

Cancel
------

Click **Cancel** to stop the replacement.

.. image :: Cancel.png

Interactive Spell Check
-----------------------

The interactive mode is on by setting the argument **interactive: true** when declaring the plugin. It will perform the check as the user types.

.. image :: InteractiveSpellCheck.png

Right click on the unrecognized word and the context menu will be displayed. You can take one of the following actions.

* Select a suggested word.
* Click **Skip this** to skip this word.
* Click **Skip all** like this to skip all the word like this.
* Click **Add to dictionary** to add this word into the dictionary.

.. image :: Menu.png

Customize the language preference
---------------------------------

Because different languages may have different ways to identify a "word", SpellCheck plugin provides developers with an interface to define their own words. Follow the steps below to customize the word definition.

* Declare a class that inherits from dojox.editor.plugins._SpellCheckParser
* Implement the methods parseIntoWords: function(/*String*/ text) and getIndices: function()
* Register the parser.

If there is more than one parser, the first registered one wins. An example follows.

.. js ::

  dojo.provide("dojox.editor.plugins._CustomizedSpellCheckParser");
  
  dojo.require("dojox.editor.plugins._SpellCheckParser");
  
  dojo.declare("dojox.editor.plugins._CustomizedSpellCheckParser", dojox.editor.plugins._SpellCheckParser, {
   lang: "userDefined",
   
   parseIntoWords: function(/*String*/ text){
    // summary:
    //  Parse the text into words
    // text:
    //  Plain text without html tags
    // tags:
    //  public
    // returns:
    //  Array holding all the words
    function isCharExt(c){
     var ch = c.charCodeAt(0);
     return 48 <= ch && ch <= 57 || 65 <= ch && ch <= 90 || 97 <= ch && ch <= 122;
    }
  
    var words = this.words = [],
     indices = this.indices = [],
     index = 0,
     length = text && text.length,
     start = 0;
    
    while(index < length){
     var ch;
     // Skip the whitespace character and need to treat HTML entity respectively
     while(index < length && !isCharExt(ch = text.charAt(index)) && ch != "&"){ index++; }
     if(ch == "&"){ // An HTML entity, skip it
      while(++index < length && (ch = text.charAt(index)) != ";" && isCharExt(ch)){}
     }else{ // A word
      start = index;
      while(++index < length && isCharExt(text.charAt(index))){}
      if(start < length){
       words.push(text.substring(start, index));
       indices.push(start);
      }
     }
    }
    
    return words;
   },
   
   getIndices: function(){
    // summary:
    //  Get the indices of the words. They are in one-to-one correspondence
    // tags:
    //  public
    // returns:
    //  Index array
    return this.indices;
   }
  });
  
  // Register this parser in the SpellCheck plugin.
  dojo.subscribe(dijit._scopeName + ".Editor.plugin.SpellCheck.getParser", null, function(sp){
   if(sp.parser){ return; }
   sp.parser = new dojox.editor.plugins._SpellCheckParser();
  });

A11Y Considerations
===================

All fields within the Batch Spell Check dialog can be accessed with the keyboard.

Limitations
===========

None.

Examples
========

Basic Usage
-----------

.. code-example::
  :djConfig: parseOnLoad: true
  :version: 1.4

  .. js ::

      dojo.require("dijit.Editor");
      dojo.require("dojox.editor.plugins.SpellCheck");

  .. css ::

      @import "{{baseUrl}}dojox/editor/plugins/resources/css/SpellCheck.css";
    
  .. html ::

    <div data-dojo-type="dijit/Editor" id="editor" data-dojo-props="extraPlugins:[{name: 'SpellCheck', url: 'spellCheck.php', interactive: true, timeout: 20, bufferLength: 100, lang: 'en'}]">
    <div>
    <br>
    blah blah & blah!
    <br>
    </div>
    <br>
    <table>
    <tbody>
    <tr>
    <td style="border-style:solid; border-width: 2px; border-color: gray;">One cell</td>
    <td style="border-style:solid; border-width: 2px; border-color: gray;">
    Two cell
    </td>
    </tr>
    </tbody>
    </table>
    <ul>
    <li>item one</li>
    <li>
    item two
    </li>
    </ul>
    </div>

See Also
========

* :ref:`dijit.Editor <dijit/Editor>`
* :ref:`dijit._editor.plugins <dijit/_editor/plugins>`
* :ref:`dojox.editor.plugins <dojox/editor/plugins>`
