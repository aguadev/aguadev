.. _dojo/xhrPost:

============
dojo.xhrPost
============

:since: V0.9

.. contents ::
   :depth: 2

*Deprecated* - See :ref:`dojo/request/xhr <dojo/request/xhr>` instead.

Introduction
============

The dojo.xhrPost() function is another the cornerstone function of AJAX development.  Much like its :ref:`GET counterpart <dojo/xhrGet>` (dojo.xhrGet), its purpose is to provide an easy to use and consistent interface to making asynchronous calls.  The dojo.xhrPost is geared towards  sending data to the server, most often by posting FORM data, or some content body.  This function, in essence, implements making an asynchronous HTTP POST request.

The following information should get you up and going with dojo.xhrPost().  As with all dojo functions, always refer to the API docs for detailed information.

Limitations
===========

* Unable to post binary data. Consider :ref:`dojo.io.iframe <dojo/io/iframe>`
* The limitations are the same as :ref:`dojo.xhrGet <dojo/xhrGet>`

Usage
=====

The xhrPost() function takes an object as its parameter.  This object defines how the xhrPost should operate.  All the :ref:`dojo.xhrGet parameters <dojo/xhrGet>` are valid, including how to set the load and errors handlers.  So, for specific information about those parameters, please refer to dojo.xhrGet.  This page only lists out the parameters which are usually only used in conjunction with an HTTP POST request.

dojo.xhrPost supported object properties
----------------------------------------

All of the dojo.xhrGet :ref:`object properties <dojo/xhrGet>`

+------------------+---------------------------------------------------------------------------------------------------------------------------------+
|**content**       |A JavaScript object of name/string value pairs. xhrPost will convert this into proper POST format and send it with the post      |
|                  |data. Note that this parameter is handled differently from :ref:`dojo.xhrGet <dojo/xhrGet>`, which encodes it as a query string  |
|                  |in url.                                                                                                                          |
|                  |                                                                                                                                 |
|                  |**This parameter is optional**                                                                                                   |
+------------------+---------------------------------------------------------------------------------------------------------------------------------+
|**form**          |For posting FORM data, you can provide either the DOM node of your form or the ID of the form. xhrPost will convert              |
|                  |this into proper POST format and send it with the post data.  If a url is not set in the args to dojo.xhrPost, then it tries     |
|                  |to extract the url from the form 'action' attribute.                                                                             |
|                  |                                                                                                                                 |
|                  |**This parameter is optional**                                                                                                   |
+------------------+---------------------------------------------------------------------------------------------------------------------------------+
|**postData**      |A string of data you wish to send as the post body.  dojo.xhrPost (and dojo.rawXhrPost), do not do any processing of this        |
|                  |It is merely passed through as the POST body.                                                                                    |
|                  |                                                                                                                                 |
|                  |**This parameter is optional**                                                                                                   |
+------------------+---------------------------------------------------------------------------------------------------------------------------------+

**content**, **form**, and **postData** are mutually exclusive parameters. Please use only one at a time.

If you want to send some parameters in a query string, while making POST, you should include them in url yourself. Dojo provides a special helper for that: :ref:`dojo.objectToQuery() <dojo/objectToQuery>`, which can convert a dictionary into a valid query string --- just like :ref:`dojo.xhrGet <dojo/xhrGet>` does.

Return type (dojo.Deferred)
---------------------------

The return type is the same as dojo.xhrGet.  Please refer to the :ref:`return type <dojo/xhrGet>` documentation for details.

Handling Status Codes
---------------------

Handling status codes for xhrPost is the same as handling them for xhrGet.  Please refer to the dojo.xhrGet :ref:`status code documentation <dojo/xhrGet>` for details.

Examples
========


For specific examples of how to use dojo.xhrPost, please refer to the following.  You can use Firebug with Firefox to see dojo making the xhr requests and the generated POST data.  For Internet Explorer, you will need to use a debugging proxy like 'Charles'.

Example 1: dojo.xhrPost call to send a form
-------------------------------------------


.. code-example::

  .. js ::

      dojo.require("dijit.form.Button");
      dojo.require("dijit.form.TextBox");
      dojo.require("dijit.form.CheckBox");

      function sendForm(){
        var form = dojo.byId("myform");

        dojo.connect(form, "onsubmit", function(event){
          // Stop the submit event since we want to control form submission.
          dojo.stopEvent(event);

          // The parameters to pass to xhrPost, the form, how to handle it, and the callbacks.
          // Note that there isn't a url passed.  xhrPost will extract the url to call from the form's
          //'action' attribute.  You could also leave off the action attribute and set the url of the xhrPost object
          // either should work.
          var xhrArgs = {
            form: dojo.byId("myform"),
            handleAs: "text",
            load: function(data){
              dojo.byId("response").innerHTML = "Form posted.";
            },
            error: function(error){
              // We'll 404 in the demo, but that's okay.  We don't have a 'postIt' service on the
              // docs server.
              dojo.byId("response").innerHTML = "Form posted.";
            }
          }
          // Call the asynchronous xhrPost
          dojo.byId("response").innerHTML = "Form being sent..."
          var deferred = dojo.xhrPost(xhrArgs);
        });
      }
      dojo.ready(sendForm);

  .. html ::

    <b>Simple Form:</b>
    <br>
    <blockquote>
      <form action="postIt" id="myform">
        Text: <input type="text" data-dojo-type="dijit/form/TextBox" name="formInput" value="Some text"></input><br><br>
        Checkbox: <input type="checkbox" data-dojo-type="dijit/form/CheckBox" name="checkboxInput"></input><br><br>
        <button type="submit" data-dojo-type="dijit/form/Button" id="submitButton">Send it!</button>
      </form>
    </blockquote>
    <br>
    <b>Result</b>
    <div id="response"></div>

Example 2: dojo.xhrPost call to send some text data
---------------------------------------------------

.. code-example::

  .. js ::

      dojo.require("dijit.form.Button");

      function sendText(){
        var button = dijit.byId("submitButton2");

        dojo.connect(button, "onClick", function(event){
          // The parameters to pass to xhrPost, the message, and the url to send it to
          // Also, how to handle the return and callbacks.
          var xhrArgs = {
            url: "postIt",
            postData: "Some random text",
            handleAs: "text",
            load: function(data){
              dojo.byId("response2").innerHTML = "Message posted.";
            },
            error: function(error){
              // We'll 404 in the demo, but that's okay.  We don't have a 'postIt' service on the
              // docs server.
              dojo.byId("response2").innerHTML = "Message posted.";
            }
          }
          dojo.byId("response2").innerHTML = "Message being sent..."
          // Call the asynchronous xhrPost
          var deferred = dojo.xhrPost(xhrArgs);
        });
      }
      dojo.ready(sendText);

  .. html ::

    <b>Push the button to POST some text.</b>
    <br>
    <br>
    <button data-dojo-type="dijit/form/Button" id="submitButton2">Send it!</button>
    <br>
    <br>
    <b>Result</b>
    <div id="response2"></div>

Example 3: dojo.xhrPost call to send some JSON data
---------------------------------------------------

To send JSON, encode the JSON in the ``postData`` attribute. This may seem counter-intuitive considering the ``content`` attribute takes a JSON object; the problem is that the object is parsed into POST key-value pairs. Thus ``postData`` should be used to send raw JSON, for instance to a REST service. 

.. code-example::

  .. js ::

      dojo.require("dijit.form.Button");

      function sendText(){
        var button = dijit.byId("submitButton2");

        dojo.connect(button, "onClick", function(event){
          // The parameters to pass to xhrPost, the message, and the url to send it to
          // Also, how to handle the return and callbacks.
          var xhrArgs = {
            url: "{{baseUrl}}dojo/dojo.js",
            postData: dojo.toJson({key1:"value1",key2:{key3:"value2"}}),
            handleAs: "text",
            load: function(data){
              dojo.byId("response2").innerHTML = "Message posted.";
            },
            error: function(error){
              // We'll 404 in the demo, but that's okay.  We don't have a 'postIt' service on the
              // docs server.
              dojo.byId("response2").innerHTML = "Message posted.";
            }
          }
          dojo.byId("response2").innerHTML = "Message being sent..."
          // Call the asynchronous xhrPost
          var deferred = dojo.xhrPost(xhrArgs);
        });
      }
      dojo.ready(sendText);

  .. html ::

    <b>Push the button to POST some JSON.</b>
    <br>
    <br>
    <button data-dojo-type="dijit/form/Button" id="submitButton2">Send it!</button>
    <br>
    <br>
    <b>Result</b>
    <div id="response2"></div>

See also
========

* :ref:`dojo.xhrGet <dojo/xhrGet>`
* :ref:`dojo.xhrPut <dojo/xhrPut>`
* :ref:`dojo.rawXhrPut <dojo/rawXhrPut>`
* :ref:`dojo.xhrDelete <dojo/xhrDelete>`
