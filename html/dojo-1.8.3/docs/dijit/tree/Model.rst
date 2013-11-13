.. _dijit/tree/Model:

================
dijit.tree.Model
================

A :ref:`dijit.Tree <dijit/Tree>` presents a view onto some hierarchical data.
The "TreeModel" represents the actual data.

Usually, the data ultimately comes from a data store, but the Tree
interfaces with a "dijit.tree.Model", an Object matching a certain API of methods the tree needs.
This allows Tree to access data in various formats, such as with a data store where items
reference their parents (ie, the relational model):

.. js ::

 {name: 'folder1', type: 'directory'},
 {name: 'file1', type: file, parent: 'folder1'}

rather than parents having a list of their children:

.. js ::

 {name: 'folder1', type: 'directory', children: ['file1']}


Dijit includes a model implementation that interfaces to the new :ref:`dojo.store <dojo/store>` API:

  * :ref:`dijit.tree.ObjectStoreModel <dijit/tree/ObjectStoreModel>`: interface to a dojo.store.

It also includes two legacy models for interfacing to the deprecated :ref:`dojo.data <dojo/data>`:

  * :ref:`dijit.tree.TreeStoreModel <dijit/tree/TreeStoreModel>`: interface to a data store with a single item that represents the root of the tree.  For example, a data store of employees where the root is the CEO of the company.
  * :ref:`dijit.tree.ForestStoreModel <dijit/tree/ForestStoreModel>`: interface to a data store with multiple top level items.  For example, a data store of places (countries, states, cities).  If the data store doesn't have a single root item ("world" in this example) then ForestStoreModel is the interface for it.

The above models have the following functions:

  * respond to queries from Tree widget about items and the hierarchy of items
  * notify the tree when underlying items in the data store have changed; could be:

    * new items
    * deleted items
    * changed items (for example, item name has changed)
    * item's list of children has changed

  * handle "writes" from the Tree back to the data store, by DnD.  DnD could be of items within the tree, or items dropped from an external location.

The full API for a model is documented at `dijit.tree.model <http://api.dojotoolkit.org/jsdoc/HEAD/dijit.tree.model>`_.

The most important methods (ie, the ones that you are likely to need to override when using :ref:`dijit.tree.TreeStoreModel <dijit/tree/TreeStoreModel>` or :ref:`dijit.tree.ForestStoreModel <dijit/tree/ForestStoreModel>`) are:

getChildren()
-------------
As documented above, getChildren() can work in various ways, depending on the structure of the data.
Implementing a custom getChildren() method is what allows accessing data in the first example above, where children
reference their parent rather than vice-versa.

mayHaveChildren()
-----------------
For efficiency reasons, Tree doesn't want to query for the children of an item until it needs to display them.
It doesn't want to query for children just to see if it should draw an expando (+) icon or not.

Thus, the method mayHaveChildren() returning true indicates that either:

  * the item has children
  * the item may have children but we'd have to query to find out

The default implementation of mayHaveChildren() checks for existence of the children attribute in the item
(this assumes that parents point to their children rather than vice-versa), but it can and sometimes should be
overridden to operate based on the type of item, for example:


.. js ::

         return myStore.getValue(item, 'type') == 'folder';


pasteItem()
-----------
pasteItem() is called when something is dropped onto the Tree, and it's job is to update the data store.
That sounds fairly simple, but it becomes complex when [you are using :ref:`dijit.tree.ForestStoreModel <dijit/tree/ForestStoreModel>` and]
the node being dropped will become a top level item in the data store.

For example, imagine that your data store contains all the countries in the world,
and you are using :ref:`dijit.tree.ForestStoreModel <dijit/tree/ForestStoreModel>` to fabricate a top-level Tree node
called "World" that parents the countries.
If the user drops a new country under "World",
it needs to be added to the data store with some kind of flag indicating that it's a top-level node,
and that code has to be custom written.

Similarly, if the data store has child elements point to their parents, rather than vice-versa, and the user reorders the children
of a node, that ordering information needs to be persisted somehow to the data store.


onChildrenChange()
------------------
onChildrenChange() just notifies the tree about changes to a node's children, which is generally simple,
but similar to above it needs to have special handling for top-level nodes in the data store.
For example, if someone inserted a new country in the countries database listed above,
the model would somehow need to realize that the data had changed, and notify the Tree that "world" had a new child.
