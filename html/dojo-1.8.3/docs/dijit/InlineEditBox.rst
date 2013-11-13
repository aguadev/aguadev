.. _dijit/InlineEditBox:

===================
dijit/InlineEditBox
===================

:Project owner: Bill Keese
:since: V1.0

.. contents ::
    :depth: 3

InlineEditBox is best described as a behavior on some text on the page, such that clicking that text brings up an editor, and when the text is saved, the screen is reverted to it's original state (but with the new text).
The editor is created on-demand, so as to not slow down page load.


Programmatic InlineEditBox
==========================

.. code-example ::

  .. js ::

    require(["dijit/InlineEditBox", "dijit/form/Textarea", "dojo/domReady!"], function(InlineEditBox, Textarea){
        var eb = new InlineEditBox({
            editor: Textarea,
            autoSave: false
        }, "ieb");
    });

  .. html ::

    <div id="ieb">
        When you click on this div you'll be able to edit it (in plain text).
        The editor's size will initially match the size of the (original) text, but will expand/contract as you type.
    </div>

Note that it was created with autoSave=false to make save/cancel buttons appear.
Otherwise, the return key will end the edit, which is not appropriate for a multi-line edit.

Markup
======

Creation from markup is even easier.
Here's an example with an initial value.

.. code-example ::

  .. js ::

    require(["dojo/parser", "dijit/InlineEditBox", "dijit/form/NumberSpinner"]);

  .. html ::

    <span data-dojo-type="dijit/InlineEditBox" data-dojo-props="editor:'dijit/form/NumberSpinner', editorParams:{constraints: {places:0} }" width="70px" title="quantity">15</span>

Initial blank value
===================

If the InlineEditBox has no value it displays an icon so that the user has something to click to start the edit.
Note also that the width argument is important so to indicate the editors width, which otherwise would be undefined.

.. code-example ::

  .. js ::

    require(["dojo/parser", "dijit/InlineEditBox", "dijit/form/NumberTextBox"]);

  .. html ::

    <span data-dojo-type="dijit/InlineEditBox" data-dojo-props="editor:'dijit/form/NumberTextBox'" title="quantity" width="70px"></span>


Rich Text Editor
================

To have an InlineEditBox with the Editor, you should use the renderAsHTML=true flag, because the editor's value is HTML rather
than plain text.
This rule applies to any widget whose value is HTML rather than plain text.

Also note that you must use a <div> tag for the InlineEditBox when it embeds an editor, not a <p> or <span>.
This avoids
problems with nested <p> tags, since the Editor's value can contain <p> tags.
IE has errors with nested <p> tags since they are
invalid HTML.

To make the editor's initial size match the size the readonly text (ie, the size of the InlineEditBox before clicking it), set editorParams="{height: '', extraPlugins: ['dijit._editor.plugins.AlwaysShowToolbar']}"

.. code-example ::

  .. js ::

    require(["dojo/parser", "dijit/InlineEditBox", "dijit/Editor", "dijit/_editor/plugins/AlwaysShowToolbar"]);

  .. html ::

    <div data-dojo-type="dijit/InlineEditBox" data-dojo-props="editor:'dijit/Editor', renderAsHtml:true, autoSave:false,
        editorParams:{height: '', extraPlugins: ['dijit._editor.plugins.AlwaysShowToolbar']}"></div>

Notes on i18n
=============

Note that the web server is responsible for the initial formatting of the data.
For example, if you are display a large number, it would be formatted as 123,456,789.55 in the United States
but as 123.456.789,00 in some European countries.
InlineEditBox expects the number to be formatted in the page's locale and will fail if it can't parse it according to that locale.


Accessibility
=============

General Behavior
----------------

When InlineEditBoxes are "closed" they appear as text but are tab stops in the keyboard focus ring and have an accessible role of button.
They can have autoSave or non-autoSave behavior.
When a non-autoSave InlineEditBox is open it has associated Save and Cancel buttons.
An autoSave InlineEditBox does not have these buttons and they act like miniature forms or dialogs,
i.e pressing the Esc key will close the widget and pressing the Enter key will close the widget, saving and displaying the text.
Note that since InlineEditBoxes may be used on the page without a traditional label element,
the developer should add a title attribute in order to provide a description that is available to screen reader users.
The title will also be displayed by the browser when the user places the mouse over the element.

Keyboard
--------

Widget is closed (not being edited)

==============================================    =================================================
Action                                            Key
==============================================    =================================================
Navigate to the next widget in the tab order.     Tab
Navigate to the prior widget in the tab order.    Shift+Tab
Open the widget.                                  Enter or spacebar
==============================================    =================================================

Note: The Esc key is ignored.


TextBox with autoSave
~~~~~~~~~~~~~~~~~~~~~

+-----------------------------------------------+--------------+-------------------------------------------------------------+
|  **Action**                                   | **Key**      | **Comments**                                                |
+-----------------------------------------------+--------------+-------------------------------------------------------------+
| Navigate to the next widget in the tab order. | Tab          | The data is saved and the widget closes.                    |
+-----------------------------------------------+--------------+-------------------------------------------------------------+
| Navigate to the prior widget in the tab order.| Shift+Tab    |  The data is saved and the widget closes.                   |
+-----------------------------------------------+--------------+-------------------------------------------------------------+
| Close the TextBox, saving changes..           | Enter        | Keyboard focus is on the closed InlineEditBox.              |
+-----------------------------------------------+--------------+-------------------------------------------------------------+
| Close the TextBox, discarding changes.        | Esc          | Cancels the edit, discarding any changes.                   |
+-----------------------------------------------+--------------+-------------------------------------------------------------+


Textarea with autoSave
~~~~~~~~~~~~~~~~~~~~~~
+-----------------------------------------------+--------------+-------------------------------------------------------------+
|  **Action**                                   | **Key**      | **Comments**                                                |
+-----------------------------------------------+--------------+-------------------------------------------------------------+
| Navigate to the next widget in the tab order. | Tab (twice   | The data is saved and the widget closes.                    |
|                                               | in Firefox 2)|                                                             |
+-----------------------------------------------+--------------+-------------------------------------------------------------+
| Navigate to the prior widget in the tab order.| Shift+Tab    |  The data is saved and the widget closes.                   |
+-----------------------------------------------+--------------+-------------------------------------------------------------+
| Enter a newline into the text.                | Enter        | There is no equivalent to the Enter key behavior of         |
|                                               |              | TextBoxes to close the textarea. The user would have to     |
|                                               |              | use something like Tab and Shift + Tab                      |
+-----------------------------------------------+--------------+-------------------------------------------------------------+
| Close the Textarea, discarding changes.       | Esc          | Cancels the edit, discarding any changes.                   |
+-----------------------------------------------+--------------+-------------------------------------------------------------+

                                                               
TextBox or TextArea without autoSave
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

+-----------------------------------------------+--------------+-------------------------------------------------------------+
|  **Action**                                   | **Key**      | **Comments**                                                |
+-----------------------------------------------+--------------+-------------------------------------------------------------+
| Navigate to the Save or Cancel button.        | Tab (twice   | Focus changes to the Save button if the data has been       |
|                                               | for TextArea | changed, otherwise it moves to the Cancel button.           |
|                                               | in Firefox 2)|                                                             |
+-----------------------------------------------+--------------+-------------------------------------------------------------+
| Navigate to the prior widget in the tab order.| Shift+Tab    | The TextBox/TextArea remains open.                          |
+-----------------------------------------------+--------------+-------------------------------------------------------------+
| Close the TextBox/TextArea, saving changes.   | Tab to save  | Keyboard focus is on the closed InlineEditBox.              |
|                                               | button and   |                                                             |
|                                               | press Enter  |                                                             |
+-----------------------------------------------+--------------+-------------------------------------------------------------+
| Close the Textbox/TextArea, discarding changes| Tab to cancel| Keyboard focus is on the closed InlineEditBox.              |
|                                               | button and   |                                                             |
|                                               | press Enter  |                                                             |
+-----------------------------------------------+--------------+-------------------------------------------------------------+

Notes:
 
- The Enter key is ignored when focus is in the Textbox edit field.
- In a TextArea pressing the Enter key results in a newline.

Known Issues
------------

On Firefox 2, the user must press the Tab key twice with focus in an textarea before keyboard focus moves to the next widget.
This is a permanent restriction on Firefox 2.
This is because the Dojo text area is implemented using the Firefox editor component in an iframe.
This editor component implements usage of the tab key within the editor to indent text and shift-tab to outdent text.
There is no keyboard mechanism in Firefox to move focus out of the editor.
So, the dijit editor traps the tab key in the editor and sets focus to the editor iframe.
From there pressing tab again will move to the next focusable item after the editor.

Screen Reader
~~~~~~~~~~~~~

The InlineEditBox is implemented as a button.
Since these are intended to be used "in-line" within text there is often no label element associated with the underlying control.
For this reason, developers are encouraged to add a title attribute to InlineEditBoxes.
The Window-Eyes screen reader will speak the title as part of the button description.
JAWS has an option to speak different attributes on an button.
A JAWS user may need to use the insert-v command to modify the behavior to speak the button title when working with Dojo InlineEditBoxes.
