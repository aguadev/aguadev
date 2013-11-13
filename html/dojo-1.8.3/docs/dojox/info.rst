.. _dojox/info:

=======================================
DojoX - Dojo Extensions and Experiments
=======================================


DojoX is an area for development of extensions to the Dojo toolkit.  It acts as an incubator for new ideas, a testbed for experimental additions to the main toolkit, as well as a repository for more stable and mature extensions.  Unlike Dojo and :ref:`Dijit <dijit/index>`, DojoX is managed by subprojects, each of which has at least one module, a sponsor and a mission statement.  [Release cycle policy TBD]  The subprojects may have dependencies on Dojo and Dijit code or other subprojects in DojoX.  Some subprojects may choose to keep their dependencies on Dojo minimal, perhaps only depending on Dojo Base, and remain largely toolkit agnostic. Other DojoX sub-projects directly extend Dojo or Dijit components, like the :ref:`Flickr data store <dojox/data/FlickrRestStore>` and :ref:`dojox.color <dojox/color>`.

Some caveats of using DojoX
---------------------------

* The condition and level of support of DojoX code will vary, from **experimental** through **production**.  DojoX subprojects may disappear entirely if unsuccessful or abandoned.
* Unlike Dojo and Dijit, DojoX modules are **not** guaranteed to be fully accessible or internationalized
* DojoX subprojects may be moved to Dijit or Dojo Core, subject to project lead approval, the needs of the toolkit and the capacity of those teams to absorb additional code.
* Fully mature, production level code will typically remain in DojoX.
* Not all modules in DojoX will be documented, since they are lower priority than Base and Core.

Browse the `API documentation <http://dojotoolkit.org/api/dojox.html>`_ and `subversion repository <http://svn.dojotoolkit.org/src/dojox/trunk>`_ directly for a more complete list.

Project Status
--------------
A DojoX subproject's status can be found within the README file within the top directory of the subproject.  README files are mandatory, and status changes must be approved by the DojoX BDFL.  These are the possible states for a DojoX subproject:

* **experimental**. A subproject which may be new or a proof of concept.  It is somewhat functional but may also be highly unstable and subject to change or removal without notice.
* **alpha**.  A subproject in alpha status shows a higher level of commitment than experimental, but is still subject to change without notice.  Unit tests are required, but may not all run successfully.
* **beta**.  A subproject in beta status is considered somewhat stable.  API changes may occur as needed, but will be documented at release.  For a subproject to be considered for beta, **unit tests must all pass** and **full inline documentation is required**.
* **production**.  A production level subproject follows the same conventions as Dojo Core and Dijit: a major release cycle and deprecation cycle is required for all incompatible API changes.  i18n and a11y compliance are desirable, but not required, and will be documented in the README.  An entry in these Dojo Documentation pages is **required**.

Naming Conventions
------------------

DojoX follows the same naming conventions as Dojo and Dijit, which basically consists of:

* Functions are mixed case, always starting with a lowercase. Eg: ``dojox.cometd.init("http://cometserver:9090/cometd");``
* Classes are Capitalized, eg: ``new dojox.image.Lightbox``, to create a Lightbox from the :ref:`dojox.image project <dojox/image>`
* All namespaces exist withing their project name. No classes exist in the top-level dojox namespace, with one notable exception: ``dojox.Grid``. This Grid module is deprecated, and will be gone in 2.0. It will be replaced with :ref:`dojox.grid.DataGrid <dojox/grid/DataGrid>`
* No cross-namespace pollution takes place indirectly.

There is, however, a supported convention for DojoX to add or modify functionality in Dojo or Dijit: **hyphens**. By adding a hyphen to the
module name, it is meant to be clear the module modifies something elsewhere in Dojo.

For instance, ``dojox.fx.ext-dojo.NodeList`` adds :ref:`dojox.fx <dojox/fx>` functionality into :ref:`dojo.NodeList <dojo/NodeList>`, making it available from a :ref:`dojo.query <dojo/query>` call.

The rational is: Because the hypen is illegal in JavaScript variables, you will never be able to directly call an ``ext-dojo`` method directly, and the act of :ref:`requiring <dojo/require>` it mixes the desired functionality in the appropriate place.

Contributing to DojoX
---------------------

Contributing new projects, or patches for existing projects are covered under the same rules as Dojo and Dijit. Code must adhere to The Dojo `Style Guidelines <developer/styleguide>`_, and be covered under a `Contributor License Agreement <http://dojotoolkit.org/cla>`_ to ensure
it may be distributed. Accepting a new project or patch for an existing project is left to the discretion of the project "owner", or in the case of top-level project, the DojoX BDFL (currently: Adam Peller)

You are obviously more than welcome to create your own projects and modules that use the Dojo Toolkit and not contribute them to directly back to DojoX. Feel free to blog, design, and otherwise innovate using the Toolkit, and release it independently, though **contact us**, as we would love to evangelize your efforts!

External Modules
----------------

No convention currently exists for external modules in DojoX. For Dojo 2.0, the DojoX project will likely be "decoupled" and treated as entirely external through an undermined mechanism for package retrieval.

See Also
--------

* `plugd <http://github.com/phiggins42/plugd>`_ is an example of an additional name space which does **not** follow the hypen extension policy.
