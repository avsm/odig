(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(** Mining OCaml package installs.

    Consult the {{!toplevel}toplevel helpers} and the {{!api}Odig API}.

    {b Warning.} [Odig] is a work in progress. Do not expect these
    APIs to be stable.

    {e %%VERSION%% — {{:%%PKG_HOMEPAGE%% }homepage}} *)

(** {1:toplevel Toplevel helpers}

    {b WARNING.} Proof of concepts do not start using this in your
    scripts. For now only available in the bytecode toplevel.

    To use the toplevel helpers simply bring the [Odig] module
    in your scope: type or add the following line to your
    [~/.ocamlinit] file.
{[#use "odig.top"]}

   {2:loadsem Load semantics and effects}

    Take into account the following points:
    {ul
    {- Loading an object means: add its containing directory to the
       included directories, load the object and (if not prevented)
       its dependencies.}
    {- If an object is available both as a standalone file and in a library
       archive, [Odig] favours loading the library archive.}
    {- When a library archive [lib] is loaded, if there is a file called
       [lib_top_init.ml] at the same location that file is loaded aswell,
       This can be prevented by using the [~init] argument of
       load functions.}
    {- Library archive with the following filenames are currently prevented
       from loading: [ocamltoplevel.cma], [ocamlbytecomp.cma], [stdlib.cma]}
    {- In {!load_libs} and {!load_pkg}, library archives ending with [_top.cma]
       are excluded from the libraries to load.}
    {- Dependency searches are currently unrestricted. This semantics will
       change in the future, notably to ensure reproducible results regardless
       of the package install state.}} *)

(** {2:localsearch Local search}

    Some functions take a [~dir] argument that specifies a directory
    where objects can be looked up in addition to packages.  This
    directory defaults to [_build] or the value of the environment
    value [ODIG_TOP_LOCAL_DIR]. These load functions always first look up
    for objects locally and then in packages. *)

(** {2:loaders Loaders} *)

val help : unit -> unit
(** [help ()] shows help about odig's toplevel support. *)

val status : unit -> unit
(** [status] outputs information about Odig's toplevel loads. *)

val reset : unit -> unit
(** [reset] removes odig included directories and pretend all odig loaded
    objects were not. *)

val load :
  ?force:bool -> ?deps:bool -> ?init:bool -> ?dir:Fpath.t -> string -> unit
(** [load ~force ~deps ~init ~dir "Mod"] loads and setups include directories
    for the module [Mod] found in [dir] or in any package.
    {ul
    {- If [init] is [true] (default) toplevel library initialisation files
       are loaded.}
    {- If [deps] is [true] (default) objects that are needed by the
       module are also loaded.}
    {- If [force] is [true] (defaults to [false]) reloads any loaded
       object that needs to be loaded.}}

    {b Warning.} Do not use this function in scripts, its outcome
    depends on the package install state. *)

val load_libs :
  ?force:bool -> ?deps:bool -> ?init:bool -> ?dir:Fpath.t -> unit -> unit
(** [load_libs ~force ~deps ~init ~dir ()] loads and setups include
    directories for libraries found in [dir].
    {ul
    {- If [init] is [true] (default) toplevel library initialisation files
       are loaded.}
    {- If [deps] is [true] (default) objects that are needed by the
       libraries are also loaded.}
    {- If [force] is [true] (defaults to [false]) reloads any loaded
       object that needs to be loaded.}} *)

val load_pkg :
  ?silent:bool -> ?force:bool -> ?deps:bool -> ?init:bool -> string -> unit
(** [load_pkg ~silent ~force ~deps ~init name] loads all the libraries of the
    package named [name].
    {ul
    {- If [init] is [true] (default) toplevel library
       initialisation files are loaded.}
    {- If [deps] is [true] (default) objects in other packages that
       are needed by the package libraries are also loaded.}
    {- If [force] is [true] (defaults to [false]) reloads any loaded
       object that needs to be loaded.}
    {- If [silent] is [true] loaded objects are not logged}} *)

(**/**)
val debug : unit -> unit
(**/**)

(** {1:api Odig API} *)

(** OCaml compilation objects.

    {b Note.} All paths returned by functions of this module
    are made absolute (using {{:https://github.com/dbuenzli/bos/issues/49}for
    now}, a fake [realpath(2)]). *)
module Cobj : sig

  (** {1:cobjs Compilation objects} *)

  (** Compilation object digests. *)
  module Digest : sig

    (** {1 Digests} *)

    include module type of Digest

    val pp : Format.formatter -> t -> unit
    (** [pp ppf d] prints the digest [d] as an hexadecimal string. *)

    val pp_opt : Format.formatter -> t option -> unit
    (** [pp_opt ppf od] prints the optional digest [od] either like
        {!pp} or, for [None] as dashes. *)

    module Set : Asetmap.Set.S with type elt = t

    type set = Set.t
    (** The type for digest sets. *)

    module Map : Asetmap.Map.S_with_key_set with type key_set = Set.t
                                             and type key = t
    type 'a map = 'a Map.t
    (** The type for digest maps. *)
  end

  type digest = Digest.t
  (** The type for compilation object digests. *)

  type dep = string * digest option
  (** The type for compilation object dependencies. A module name
      and an optional digest (often a [cmi] digest). *)

  val pp_dep : dep Fmt.t
  (** [pp_dep ppf d] prints an unspecified representation of [d] on
      [ppf]. *)

  type mli
  (** The type for [mli] files. *)

  type cmi
  (** The type for [cmi] files. *)

  type cmti
  (** The type for [cmti] files. *)

  type ml
  (** The type for [ml] files. *)

  type cmo
  (** The type for [cmo] files. *)

  type cmt
  (** The type for [cmt] files. *)

  type cma
  (** The type for [cma] files. *)

  type cmx
  (** The type for [cmx] files. *)

  type cmxa
  (** The type for [cmxa] files. *)

  type cmxs
  (** The type for [cmxs] files. *)

  (** [mli] files. *)
  module Mli : sig

    (** {1 Mli} *)

    type t = mli
    (** The type for mli files. *)

    val read : Fpath.t -> (mli, [`Msg of string]) result
    (** [read f] reads an [mli] file from [f].

        {b Warning.} Does only check the file exists, not that it is
        syntactically correct. *)

    val name : mli -> string
    (** [name mli] is the name of the module interface. *)

    val path : mli -> Fpath.t
    (** [path mli] is the file path to the mli file. *)
  end

  (** [cmi] files. *)
  module Cmi : sig

    (** {1 Cmi} *)

    type t = cmi
    (** The type for cmi files. *)

    val read : Fpath.t -> (cmi, [`Msg of string]) result
    (** [read f] reads a [cmi] file from [f]. *)

    val name : cmi -> string
    (** [name cmi] is the name of the module interface. *)

    val digest : cmi -> digest
    (** [digest cmi] is the digest of the module interface. *)

    val deps : cmi -> dep list
    (** [deps cmi] is the list of imported module interfaces names with their
        digest, if known. *)

    val path : cmi -> Fpath.t
    (** [path cmi] is the file path to the [cmi] file. *)

    (** {1 Derived information} *)

    val to_cmi_dep : cmi -> dep
    (** [to_cmi_dep cmi] is [cmi] as a dependency. *)
  end

  (** [cmti] files. *)
  module Cmti : sig

    (** {1 Cmti} *)

    type t = cmti
    (** The type for [cmti] files. *)

    val read : Fpath.t -> (cmti, [`Msg of string]) result
    (** [read f] reads a [cmti] file from [f]. *)

    val name : cmti -> string
    (** [name cmti] is the name of the module interface. *)

    val digest : cmti -> digest
    (** [digest cmti] is the digest of the module interface. *)

    val deps : cmti -> dep list
    (** [deps cmti] is the list of imported module interfaces with their
        digest, if known. *)

    val path : cmti -> Fpath.t
    (** [path cmti] is the file path to the [cmti] file. *)

    (** {1 Derived information} *)

    val to_cmi_dep : cmti -> dep
    (** [to_cmi_dep cmti] is [cmti] as a dependency. *)
  end

  (** [ml] files. *)
  module Ml : sig

    (** {1 Ml} *)

    type t = ml
    (** The type for ml files. *)

    val read : Fpath.t -> (ml, [`Msg of string]) result
    (** [read f] reads an [ml] file from [f].

        {b Warning.} Does only check the file exists, not that it is
        syntactically correct. *)

    val name : ml -> string
    (** [name ml] is the name of the module interface. *)

    val path : ml -> Fpath.t
    (** [path ml] is the file path to the ml file. *)
  end

  (** [cmo] files. *)
  module Cmo : sig

    (** {1 Cmo} *)

    type t = cmo
    (** The type for [cmo] files. *)

    val read : Fpath.t -> (cmo, [`Msg of string]) result
    (** [read f] reads a [cmo] file from [f]. *)

    val name : cmo -> string
    (** [name cmo] is the name of the module implementation. *)

    val cmi_digest : cmo -> digest
    (** [cmi_digest cmo] is the digest of the module interface of the
        implementation. *)

    val cmi_deps : cmo -> dep list
    (** [cmi_deps cmo] is the list of imported module interfaces names
        with their digest, if known. *)

    val cma : cmo -> cma option
    (** [cma cmo] is an enclosing [cma] file (if any). *)

    val path : cmo -> Fpath.t
    (** [path cmo] is the file path to the [cmo] file. Note that this
        is a [cma] file if [cma cmo] is [Some _]. *)

    (** {1 Derived information} *)

    val to_cmi_dep : cmo -> dep
    (** [to_cmi_dep cmo] is [cmo] as a [cmi] dependency. *)
  end

  (** [cmt] files. *)
  module Cmt : sig

    (** {1 Cmt} *)

    type t = cmt
    (** The type for [cmt] files. *)

    val read : Fpath.t -> (cmt, [`Msg of string]) result
    (** [read f] reads a [cmt] file from [f]. *)

    val name : cmt -> string
    (** [name cmt] is the name of the module interface. *)

    val cmi_digest : cmt -> digest
    (** [cmi_digest cmt] is the digest of the module interface of the
        implementation. *)

    val cmi_deps : cmt -> dep list
    (** [cmi_deps cmt] is the list of imported module interfaces names
        with their digest, if known. *)

    val path : cmt -> Fpath.t
    (** [path cm] is the file path to the [cmt] file. *)
  end

  (** [cma] files. *)
  module Cma : sig

    (** {1 Cma} *)

    type t = cma
    (** The type for cma files. *)

    val read : Fpath.t -> (cma, [`Msg of string]) result
    (** [read f] reads a [cma] file from [f]. *)

    val name : cma -> string
    (** [name cma] is [cma]'s basename. *)

    val cmos : cma -> cmo list
    (** [cmos cma] are the [cmo]s contained in the [cma]. *)

    val custom : cma -> bool
    (** [custom cma] is [true] if it requires custom mode linking. *)

    val custom_cobjs : cma -> string list
    (** [cma_custom_cobjs] are C objects files needed for custom mode
        linking. *)

    val custom_copts : cma -> string list
    (** [cma_custom_copts] are C link options for custom mode linking. *)

    val dllibs : cma -> string list
    (** [cma_dllibs] are dynamically loaded C libraries for ocamlrun
        dynamic linking. *)

    val path : cma -> Fpath.t
    (** [path cma] is the file path to the [cma] file. *)

    (** {1 Derived information}

        FIXME most of this can be removed. *)

    val names : ?init:Digest.t Astring.String.map -> cma ->
      Digest.t Astring.String.map
    (** [names ~init cma] adds to [init] (defaults to
        {!String.Map.empty}) the module names defined by [cma] mapped
        to their [cmi] digests. If a name already exists in [init] it
        is overriden. *)

    val cmi_digests : ?init:string Digest.map -> cma -> string Digest.map
    (** [cmi_digests ~init cma] adds to [init] (defaults to
        {!Digest.Map.empty}) the [cmi] digests of the modules defined
        by [cma] mapped to their module name. If a digest already
        exists in [init] it is overriden. *)

    val to_cmi_deps : ?init:dep list -> cma -> dep list
    (** [to_cmi_deps ~init cma] adds to [init] (default to [[]])
        the module names and [cmi] digests of the modules defined
        by [cma]. *)

    val cmi_deps :
      ?conflict:(string -> keep:Digest.t -> Digest.t -> unit) ->
      cma -> dep list
    (** [cmi_deps ~conflict cma] is the list of cmi imported by the [cmo]s
        in the library. The result excludes self-dependencies
        that is the set {!cmi_digest} of digests that are implemented
        by the [cma] itself.

        [conflict] is called if the module interface of a dependency
        sports two different digests in the archive. The default
        function logs a warning. *)
  end

  (** [cmx] files. *)
  module Cmx : sig

    (** {1 Cmx} *)

    type t = cmx
    (** The type for [cmx] files. *)

    val read : Fpath.t -> (cmx, [`Msg of string]) result
    (** [read f] reads a [cmx] file from [f]. *)

    val name : cmx -> string
    (** [name cmx] is the name of the module implementation. *)

    val digest : cmx -> digest
    (** [digest cmx] is the digest of the implementation. *)

    val cmi_digest : cmx -> digest
    (** [cmi_digest cmx] is the digest of the module interface of the
        implementation. *)

    val cmi_deps : cmx -> dep list
    (** [cmi_deps cmx] is the list of imported module interfaces names
        with their digest, if known. *)

    val cmx_deps : cmx -> dep list
    (** [cmx_deps cmx] is the list of imported module implementations names
        with their digest, if known. *)

    val cmxa : cmx -> cmxa option
    (** [cmxa cmx] is an enclosing [cmxa] file (if any). *)

    val path : cmx -> Fpath.t
    (** [path cmx] is the file path to the [cmx] file. Note that this
        is a [cmxa] file if [cmxa cmx] is [Some _]. *)

    (** {1 Derived information} *)

    val to_cmi_dep : cmx -> dep
    (** [to_cmi_dep cmx] is [cmx] as a [cmi] dependency. *)
  end

  (** [cmxa] files. *)
  module Cmxa : sig

    (** {1 Cmxa} *)

    type t = cmxa
    (** The type for [cmxa] files. *)

    val read : Fpath.t -> (t, [`Msg of string]) result
    (** [read f] reads a [cmxa] file from [f]. *)

    val name : cmxa -> string
    (** [name cmxa] is [cmxa]'s basename. *)

    val cmxs : cmxa -> cmx list
    (** [cmxs cmxa] are the [cmx]s contained in the [cmxa]. *)

    val cobjs : cmxa -> string list
    (** [cobjs] are C objects needed files needed for linking. *)

    val copts : cmxa -> string list
    (** [copts] are options for the C linker. *)

    val path : cmxa -> Fpath.t
    (** [path cmxa] is the file path to the [cmxa] file. *)

    (** {1 Derived information} *)

    val names : ?init:Digest.t Astring.String.map -> cmxa ->
      Digest.t Astring.String.map
    (** [names ~init cmxa] adds to [init] (defaults to
        {!String.Map.empty}) the module names defined by [cmxa] mapped
        to their [cmi] digests. If a name already exists in [init] it
        is overriden. *)

    val cmi_digests : ?init:string Digest.map -> cmxa -> string Digest.map
    (** [cmi_digests ~init cmxa] adds to [init] (defaults to
        {!Digest.Map.empty}) the [cmi] digests of the modules defined
        by [cmxa] mapped to their module name. If a digest already
        exists in [init] it is overriden. *)

    val to_cmi_deps : ?init:dep list -> cmxa -> dep list
    (** [to_cmi_deps ~init cmxa] adds to [init] (default to [[]])
        the module names and [cmi] digests of the modules defined
        by [cmxa]. *)

    val cmi_deps :
      ?conflict:(string -> keep:Digest.t -> Digest.t -> unit) ->
      cmxa -> dep list
    (** [cmi_deps ~conflict cmxa] is the list of cmi imported by the [cmx]s
        in the library. The result excludes self-dependencies
        that is the set {!cmi_digest} of digests that are implemented
        by the [cmxa] itself.

        [conflict] is called if the module interface of a dependency
        sports two different digests in the archive. The default
        function logs a warning. *)
  end

  (** [cmxs] files. *)
  module Cmxs : sig

    (** {1 Cmxs} *)

    type t = cmxs
    (** The type for [cmxs] files. *)

    val read : Fpath.t -> (t, [`Msg of string]) result
    (** [read f] reads a [cmxs] file from [f].

        {b Warning.} Only checks that the file exists. *)

    val name : cmxs -> string
    (** [name cmxs] is [cmxs]'s basename. *)

    val path : cmxs -> Fpath.t
    (** [path cmxs] is the file path to the [cmxs] file. *)
  end

  (** {1 Compilation object sets} *)

  type set
  (** The type for sets of compilation objects. *)

  val empty_set : set
  (** [empty_set] is an empty set of compilation objects. *)

  val mlis : set -> mli list
  (** [mlis s] is the list of [mli]s contained in [s]. *)

  val cmis : set -> cmi list
  (** [cmis s] is the list of [cmi]s contained in [s]. *)

  val cmtis : set -> cmti list
  (** [cmtis s] is the list of [cmti]s contained in [s]. *)

  val mls : set -> ml list
  (** [mls s] is the list of [ml]s contained in [s]. *)

  val cmos : ?files:bool -> set -> cmo list
  (** [cmos ~files s] is the list of [cmo]s contained in [s].  If
      [files] is [true] (defaults to [false]), only the [cmo] files
      are listed and [cmo]s that are part of [cma] files are omitted. *)

  val cmts : set -> cmt list
  (** [cmts s] is the list of [cmt]s contained in [s]. *)

  val cmas : set -> cma list
  (** [cmas s] is the list of [cma]s contained in [s]. *)

  val cmxs : ?files:bool -> set -> cmx list
  (** [cmxs ~files s] is the list of [cmx]s contained in [s].  If
      [files] is [true] (defaults to [false]), only the [cmx] files
      are listed and [cmx]s that are part of [cmxa] files are omitted. *)

  val cmxas : set -> cmxa list
  (** [cmxa s] is the list of [cmxa]s contained in [s]. *)

  val cmxss : set -> cmxs list
  (** [cmxss s] is the list of [cmxs]s contained in [s]. *)

  val set_of_dir :
    ?err:(Fpath.t -> ('a, [`Msg of string]) result -> unit) ->
    Fpath.t -> set
  (** [set_of_dir ~err d] is the set of compilation objects that
      are present in the file hierarchy rooted at [d].

      This is a best-effort function, it will call [err] on errors and
      continue; at worst you'll get an {!empty_set}.  [err]'s default
      simply logs the error at level {!Logs.Error}. *)

  (** {1:indexes Compilation object indexes} *)

  type 'a index
  (** See {!Index.t}. *)

  (** Compilation object indexes *)
  module Index : sig

    (** {1 Compilation objects indexes} *)

    type 'a t = 'a index
    (** The type for compilation objects indexes whose query results
        are tagged with ['a]. *)

    val empty : 'a index
    (** [empty] is an empty index. *)

    val of_set : ?init:'a index -> 'a -> set -> 'a index
    (** [of_set ~init t s] is an index from [s] whose objects
        are tagged with [t]. [init] is the index to add to (defaults to
        {!empty}.) *)

    (** {1 Queries} *)

    type query = [`Digest of digest | `Name of string ]
    (** The type for queries. Either by digest or by (capitalized)
        module name. *)

    val query_of_dep : dep -> query
    (** [query_of_dep dep] is the most precise query for [dep]. *)

    val query :
      'a t -> query ->
      ('a * cmi) list *
      ('a * cmti) list *
      ('a * cmo) list *
      ('a * cmx) list *
      ('a * cmt) list
    (** [query i q] is [(cmis, cmtis, cmos, cmxs, cmt)] the compilations
        objects matching query [q] in [i]:
        {ul
        {- [cmis] are those whose {!Cobj.Cmi.name} or {!Cobj.Cmi.digest} match.}
        {- [cmtis] are those whose {!Cobj.Cmti.name} or
           {!Cobj.Cmti.digest} match.}
        {- [cmos] are those whose {!Cobj.Cmo.name} or
           {!Cobj.Cmo.cmi_digest} match.}
        {- [cmxs] are those whose {!Cobj.Cmx.name} or
           {!Cobj.Cmx.digest} or {!Cobj.Cmx.cmi_digest} match.}
        {- [cmts] are those whose {!Cobj.Cmt.name} or
           {!Cobj.Cmt.cmi_digest} match.}} *)

    val cmis_for_interface : 'a index -> query -> ('a * cmi) list
    (** [cmi_for_interface i q] is a list of [cmi]s whose module interface
        matches [q]. *)

    val cmtis_for_interface : 'a index -> query -> ('a * cmti) list
    (** [cmti_for_interface i q] is a list of [cmti]s whose module
        interface matches [q]. *)

    val cmos_for_interface : 'a index -> query -> ('a * cmo) list
    (** [cmo_for_interface i d] is a list of [cmo] whose module
        interface matches [q]. *)

    val cmxs_for_interface : 'a index -> query -> ('a * cmx) list
    (** [cmxs_for_interface i cmx] is a list of [cmx] objects whose
        module interface matches [q]. *)

    val cmts_for_interface : 'a index -> query -> ('a * cmt) list
    (** [cmxs_for_interface i cmx] is a list of [cmx] objects whose
        module interface matches [q]. *)
  end

  (** {1:depresolve Dependency resolution} *)

  type ('a, 'o) dep_resolution =
    [ `None | `Some of ('a * 'o) | `Amb of ('a * 'o) list ]
  (** The type for dependency resolutions. Either no, some or
      an ambiguous resolution. *)

  type ('a, 'o) dep_resolver = dep -> ('a * 'o) list -> ('a, 'o) dep_resolution
  (** The type for dependency resolvers. Determines a resolution from
      a dependency and list of matching candidates. *)

  val cmi_for_interface :
    resolve:('a, cmi) dep_resolver -> 'a index -> dep ->
    ('a, cmi) dep_resolution
  (** [cmi_for_interface ~resolve i dep] is the resolution [resolve] of
      [cmi]s matching module interface [dep] in [i]. *)

  val cmo_for_interface :
    resolve:('a, cmo) dep_resolver -> 'a index -> dep ->
    ('a, cmo) dep_resolution
  (** [cmo_for_interface ~resolve i dep] is the resolution [resolve] of
      [cmo]s matching module interface [dep] in [i]. *)

  val cmx_for_interface :
    resolve:('a, cmx) dep_resolver -> 'a index -> dep ->
    ('a, cmx) dep_resolution
  (** [cmx_for_interface ~resolve i dep] is the resolution [resolve] of
      [cmx]s matching module interface [dep] in [i]. *)

  (** {2:recdepresolve Recursive resolution} *)

  type ('a, 'o) dep_src = ('a * 'o) list
  (** The type for dependency sources. Tracks an object (head) to its source
      (tail). This is only used to allow good end-user feedback. *)

  type ('a, 'o) rec_dep_resolution =
    [ `Resolved of ('a * 'o) * ('a, 'o) dep_src
    | `Unresolved of dep * [ `None | `Amb of ('a * 'o) list ] * ('a, 'o) dep_src
    | `Conflict of string * ('a, 'o) dep_src list Digest.map ]
  (** The type for recursive dependency resolution:
      {ul
      {- [`Resolved (obj, src)], a resolved object [obj]. [src] is
         one of the sources for [obj].}
      {- [`Unresolved (dep, reason, src)], unresolved dependency [dep]
         for reason [reason]; either not found or ambiguous. [src]
         is one of the sources of [dep].}
      {- [`Conflict (n, dm)], conflicting resolution for module name
         [n]. [dm] is the set of conflicting digests for [n] mapped to one
         of their source.}} *)

  val pp_rec_dep_resolution : ('a * 'o) Fmt.t ->
    ('a, 'o) rec_dep_resolution Fmt.t
  (** [pp_rec_dep_resolution pp_obj] is an unspecified formatter
      for recursive dependency resolutions using [pp_obj] to format
      objects. *)

  val rec_cmis_for_interfaces :
    resolve:('a, cmi) dep_resolver -> 'a index ->
    (dep * ('a, cmi) dep_src) list ->
    ('a, cmi) rec_dep_resolution Astring.String.map
  (** See, {e mutatis mutandis}, {!rec_cmos_for_interfaces}. *)

  val rec_cmos_for_interfaces :
    ?cmo_deps:(cmo -> dep list) ->
    resolve:('a, cmo) dep_resolver -> 'a index ->
    (dep * ('a, cmo) dep_src) list ->
    ('a, cmo) rec_dep_resolution Astring.String.map
  (** [rec_cmos_for_interfaces ~cmo_deps ~resolve i deps] maps module names to
      the result of recursively resolving module interface
      dependencies [deps] (tupled with a dependency source) to [cmo]s
      in [i] using [resolve]. More precisely:
      {ul
      {- First [deps] are resolved to [cmo]s. Then for each of these
         [cmo]s, their interface dependencies, as determined by
         [cmo_deps] (defaults to {!Cmo.cmi_deps}) are resolved to
         [cmo]s and recursively.}
      {- Conflicts occur if two module interface dependencies occur with the
         same module name but different interface digests. This means
         that the resolution request is inconsistent and cannot be used
         for linking.}
      {- Unresolvedness may be due to: missing objects in [index], existing
         objects excluded by [resolve], ambiguous objects not decided by
         [resolve] or because a module interface has no corresponding
         implementation – the OCaml compilation model allows this.}} *)

  val fold_rec_dep_resolutions :
    deps:('o -> dep list) ->
    (string -> ('a, 'o) rec_dep_resolution -> 'b -> 'b) ->
    ('a, 'o) rec_dep_resolution Astring.String.map -> 'b -> 'b
  (** [fold_rec_dep_resolutions ~deps f res acc] folds [f] with [acc]
      over the partial evaluation order of [res] using [deps] on resolved
      objects. Conflicts and unresolved dependencies are also folded over.

      @raise Invalid_argument if [deps] returns, on a resolved object,
      a name that is not in the domain of [res]. *)
end

(** Odig configuration. *)
module Conf : sig

  (** {1 Configuration} *)

  type t
  (** The type for odig configuration. *)

  val default_file : Fpath.t
  (** [default_file] is the default configuration file. *)

  val v :
    ?trust_cache:bool -> cachedir:Fpath.t -> libdir:Fpath.t ->
    docdir:Fpath.t -> docdir_href:string option -> unit -> t
  (** [v ~trust_cache ~cachedir ~libdir ~docdir ~docdir_href ()] is a
      configuration using [cachedir] as the odig cache directory,
      [libdir] for looking up package compilation objects, [docdir]
      for looking up package documentation and [docdir_href] for
      specifying the location of [docdir] in generated html. If
      [trust_cache] is [true] (defaults to [false]) indicates the data
      of [cachedir] should be trusted regardless of whether [libdir]
      and [docdir] may have changed. *)

  val with_conf : ?trust_cache:bool -> ?docdir_href:string option -> t -> t
  (** [of_conf ~trust_cache ~docdir_href c] is [c] updated with
      arguments specified, unspecfied ones are left untouched. *)

  val of_file : ?trust_cache:bool -> Fpath.t -> (t, [`Msg of string]) result
  (** [of_file f] reads a configuration from configuration file [f].
      See {!v}. *)

  val of_opam_switch :
    ?trust_cache:bool -> ?switch:string -> ?docdir_href:string ->
    unit -> (t, [`Msg of string]) result
  (** [of_opam_switch ~switch ()] is a configuration for the opam switch
      [switch] (defaults to the current switch). See {!v}. *)

  val libdir : t -> Fpath.t
  (** [libdir c] is [c]'s package library directory. *)

  val docdir : t -> Fpath.t
  (** [docdir c] is [c]'s package documentation directory. *)

  val docdir_href : t -> string option
  (** [docdir_href c] is, for HTML generation, the base URI under
      which {!docdir} is accessible expressed (if) relative to the
      root package list.  If unspecified links to {!docdir} are made
      by relativizing {!docdir} w.r.t. to the location of the
      generated HTML file. *)

  (** {1 Cache} *)

  val cachedir : t -> Fpath.t
  (** [cachedir c] is [c]'s odig cache directory. *)

  val trust_cache : t -> bool
  (** [trust_cache c] indicates if [c] is trusting [odig]'s cache. *)

  val clear_cache : t -> (unit, [`Msg of string]) result
  (** [clear_cache c] deletes [c]'s cache directory. *)

  (** {1 Package cache} *)

  val pkg_cachedir : t -> Fpath.t
  (** [pkg_cachedir c] is [c]'s cache directory for packages it is
      located inside {!cachedir}. *)

  val cached_pkgs_names : t -> (Astring.String.set, [`Msg of string]) result
  (** [cached_pkgs_names c] is the set of names of the packages that
      are cached in [c]. Note that these packages may not correspond
      or be up-to-date with packages {{!Pkg.list}found} in the
      configuration. *)
end

(** Packages.

    Information about how packages are recognized and their data looked up
    is kept in [odig help packaging].

    {b TODO.} Add a note about freshness and concurrent access. *)
module Pkg : sig

  (** {1 Package names} *)

  type name = string
  (** The type for package names. *)

  val is_name : string -> bool
  (** [is_name n] is [true] iff [n] is a valid package name. [n]
      must not be empty and be a valid {{!Fpath.is_segment}path segment}. *)

  val name_of_string : string -> (name, [`Msg of string]) result
  (** [name_of_string s] is [Ok s] if [is_name s] is [true] and
      an error message otherwise *)

  val dir_is_package : Fpath.t -> name option
  (** [dir_is_package dir] is [Some name] if a package named [name]
      is detected in directory [dir].

      {b Note} At the moment function will not detect a package name
      if [dir] ends with a relative segment. *)

  (** {1 Packages and lookup} *)

  type t
  (** The type for packages. *)

  type set
  (** The type for package sets. *)

  val set : Conf.t -> (set, [`Msg of string]) result
  (** [set c] is the set of all packages in configuration [c].

      {b FIXME.} Currently results are memoized, which may not
      be suitable for long running programs. *)

  val conf_cobj_index :
    Conf.t -> ([`Pkg of t] Cobj.Index.t, [`Msg of string]) result
  (** [conf_cobj_cobjs c] is an index for all compilation objects in present in
      packages of configuration [c]. Query results are tagged with
      the package they belong to.

      {b FIXME.} Currently results are memoized, which may not
      be suitable for long running programs. Also this should be
      simpler to access from a given package. *)

  val lookup : Conf.t -> name -> (t, [`Msg of string]) result
  (** [lookup c n] is the package named [n] in [c]. An error
      is returned if [n] doesn't exist in [c] or if [n] is
      not a {{!is_name}package name}. *)

  val find : Conf.t -> name -> t option
  (** [find c n] tries to find a package named [n] in [c].
      [None] is returned if [n] doesn't exist in [c] or if [n]
      is not a {{!is_name}package name}. *)

  val find_set : Conf.t -> Astring.String.set -> set * Astring.String.set
  (** [find_set c ns] is [(pkgs, not_found)] where [pkgs] are
      the elements of [ns] which could be matched to a package in
      configuration [c] and [not_found] are those that could not
      be found or are not {{!is_name}package names}. *)

  (** {1 Basic properties} *)

  val field : err:'a -> (t -> ('a, [`Msg of string]) result) -> t -> 'a
  (** [field ~err field f] is [v] if [field p = Ok v] and [err] otherwise. *)

  val name : t -> name
  (** [name p] is [p]'s name. *)

  val libdir : t -> Fpath.t
  (** [libdir p] is [p]'s library directory (has the compilation objects). *)

  val docdir : t -> Fpath.t
  (** [docdir p] is [p]'s documentation directory. *)

  val cobjs : t -> Cobj.set
  (** [cobjs p] are [p]'s compilation objects. *)

  val conf : t -> Conf.t
  (** [conf p] is the configuration in which [p] was found. *)

  (** {1 Package metadata (opam file)} *)

  val opam_file : t -> Fpath.t
  (** [opam_file p] is [p]'s expected opam file path. *)

  val opam_fields :
    t -> (string list Astring.String.map, [`Msg of string]) result
  (** [opam_fields p] is the package's opam fields. This is
      {!String.Set.empty} [opam_file p] does not exist. *)

  val license_tags : t -> (string list, [`Msg of string]) result
  (** [license_tags p] is [p]'s [license:] field. *)

  val version : t -> (string option, [`Msg of string]) result
  (** [version p] is [p]'s [version:] field. *)

  val homepage : t -> (string list, [`Msg of string]) result
  (** [version p] is [p]'s [homepage:] field. *)

  val online_doc : t -> (string list, [`Msg of string]) result
  (** [online_doc p] is [p]'s [doc:] field. *)

  val issues : t -> (string list, [`Msg of string]) result
  (** [issues p] is [p]'s [bug-report:] field. *)

  val tags : t -> (string list, [`Msg of string]) result
  (** [tags p] is [p]'s [tags:] field. *)

  val maintainers : t -> (string list, [`Msg of string]) result
  (** [maintainers p] is [p]'s [maintainer:] field. *)

  val authors : t -> (string list, [`Msg of string]) result
  (** [authors p] is [p]'s [authors:] field. *)

  val repo : t -> (string list, [`Msg of string]) result
  (** [repo p] is [p]'s [dev-repo:] field. *)

  val deps : ?opts:bool -> t -> (Astring.String.set, [`Msg of string]) result
  (** [deps p] are [p]'s opam dependencies if [opt] is [true]
      (default) includes optional dependencies. *)

  val depopts : t -> (Astring.String.set, [`Msg of string]) result
  (** [deps p] are [p]'s opam optional dependencies. *)

  (** {1 Standard distribution documentation}

      See {!Odoc} and {!Ocamldoc} for generated documentation. *)

  val readmes : t -> (Fpath.t list, [`Msg of string]) result
  (** [readmes p] are the readme files of [p]. *)

  val change_logs : t -> (Fpath.t list, [`Msg of string]) result
  (** [change_logs p] are the change log files of [p]. *)

  val licenses : t -> (Fpath.t list, [`Msg of string]) result
  (** [licences p] are the license files of [p]. *)

  (** {1 Predicates} *)

  val equal : t -> t -> bool
  (** [equal p p'] is [true] if [p] and [p'] have the same name. *)

  val compare : t -> t -> int
  (** [compare p p'] is a total order on [p] and [p']'s names. *)

  (** {1 Package sets and maps} *)

  (** Package sets. *)
  module Set : Asetmap.Set.S with type elt = t and type t = set

  (** Package maps. *)
  module Map : Asetmap.Map.S_with_key_set with type key = t
                                           and type key_set = Set.t

  (** {1 Classifying} *)

  val classify :
    ?cmp:('a -> 'a -> int) -> classes:(t -> 'a list) -> t list ->
    ('a * Set.t) list

  (** {1 Cache} *)

  val cachedir : t -> Fpath.t
  (** [cachedir p] is [p]'s cache directory, located somewhere in the
      configuration's {!Conf.cachedir}. *)

  type cache_status = [ `New | `Stale | `Fresh ]
  (** The type for package status.
      {ul
        {- [`New] indicates that no cached information could be found
           for the package.}
        {- [`Fresh] indicates that cached information corresponds to the
           package install state. {b Warning.} Freshness only refers to the
           root information handled by this module. For example a
           package may be fresh but it's API documentation may be
           stale.}
        {- [`Stale] indicates that cached information does not
           correspond to the package install's state}} *)

  val cache_status : t -> (cache_status, [`Msg of string]) result
  (** [cache_status p] is [p]'s cache status. *)

  val refresh_cache : t -> (unit, [`Msg of string]) result
  (** [refresh_cache p] ensures [p]'s cache status becomes
      [`Fresh]. {b Note.} Clients usually don't need to call this
      as it is handled transparently by the API. *)

  val clear_cache : t -> (unit, [`Msg of string]) result
  (** [clear_cache p] deletes [p]'s {!cachedir}. Ensures [p]'s
      cache status becomes [`New]. *)
end

(** {1:docgen Package documentation generation} *)

(** [odoc] API documentation generation. *)
module Odoc : sig

  (** {1 Odoc} *)

  val htmldir : Conf.t -> (Pkg.t option -> Fpath.t)
  (** [htmldir c] is is a function that returns the root or package
      [odoc] HTML directory for [c]. *)

  val compile :
    odoc:Bos.Cmd.t -> force:bool -> Pkg.t -> (unit, [`Msg of string]) result
  (** [compile ~odoc ~force p] compiles the [.odoc] files from the [.cmti]
      files of package [p]. *)

  val html :
    odoc:Bos.Cmd.t -> force:bool -> Pkg.t -> (unit, [`Msg of string]) result
  (** [html ~odoc ~force p] generates the html files from the [.odoc]
      files of package [p]. *)

  val htmldir_css_and_index : Conf.t -> (unit, [`Msg of string]) result
  (** [htmldir_css_and_index c] generates the [odoc] css and html
      package index for configuration [c]. *)
end

(** [ocamldoc] API documentation generation. *)
module Ocamldoc : sig

  (** {1 Ocamldoc} *)

  val htmldir : Conf.t -> (Pkg.t option -> Fpath.t)
  (** [htmldir c] is is a function that returns the root or package
      [ocamldoc] HTML directory for [c]. *)

  val compile :
    ocamldoc:Bos.Cmd.t -> force:bool -> Pkg.t -> (unit, [`Msg of string]) result
  (** [compile ~ocamldoc ~force p] compiles the [.ocodoc] files from the [.mli]
      and [.cmi] files of package [p]. *)

  val html :
    ocamldoc:Bos.Cmd.t -> force:bool -> Pkg.t -> (unit, [`Msg of string]) result
  (** [html ~ocamldoc ~force] generates the html files from the [.ocodoc] files
      files of package [p]. *)

  val htmldir_css_and_index : Conf.t -> (unit, [`Msg of string]) result
  (** [htmldir_css_and_index c] generates the [ocamldoc] css and html
      package index for configuration [c]. *)
end

(** {1 Private} *)

(** Private definitions. *)
module Private : sig

  (** Odig log. *)
  module Log : sig

    (** {1 Log} *)

    val src : Logs.src
    (** [src] is Odig's logging source. *)

    include Logs.LOG

    val on_iter_error_msg :
        ?level:Logs.level -> ?header:string -> ?tags:Logs.Tag.set ->
        (('a -> unit) -> 'b -> 'c) ->
        ('a -> (unit, [`Msg of string]) result) -> 'b -> 'c

    val time :
      ?level:Logs.level ->
      ('a ->
       (?tags:Logs.Tag.set -> ('b, Format.formatter, unit, 'a) format4 -> 'b) ->
       'a) ->
      ('c -> 'a) -> 'c -> 'a
  end

  (** Odig toplevel support. *)
  module Top : sig

    (** {1 Toplevel support} *)

    val init : ?conf:Conf.t -> unit -> unit
    (** [init ~conf ()] initalizes the toplevel support library with [conf]
        (defaults to {!Odig.Conf.default_file}).

        {b Note.} Only call this if you need to setup another configuration.
        Initialisation happens automatically. *)

    val announce : unit -> unit
    (** [announce ppf] outputs a message that odig's toplevel support was
        setup. *)

    val assume_inc : Fpath.t -> unit
    (** [assume_inc dir] assumes that [dir] has been included. *)

    val assume_obj : Fpath.t -> unit
    (** [assume_obj obj] assumes that [obj] has been loaded. *)
  end

  (** Abtract away the OCaml's Toploop API. *)
  module Ocamltop : sig

    (** {1 Toplevel directives} *)

    val add_inc : Fpath.t -> (unit, [`Msg of string]) result
    (** [add_inc dir] add [dir] to the include path. *)

    val rem_inc : Fpath.t -> (unit, [`Msg of string]) result
    (** [rem_inc dir] remove [dir] from the include path. *)

    val load_ml : Fpath.t -> (unit, [`Msg of string]) result
    (** [load_ml ml] loads the source [ml] file. *)

    val load_obj : Fpath.t -> (unit, [`Msg of string]) result
    (** [load_obj obj] loads the [cma] or [cmo] file [obj]. *)
  end

  (** JSON text generation.

    {b Warning.} The module assumes strings are UTF-8 encoded. *)
  module Json : sig

    (** {1 Generation sequences} *)

    type 'a seq
    (** The type for sequences. *)

    val empty : 'a seq
    (** An empty sequence. *)

    val ( ++ ) : 'a seq -> 'a seq -> 'a seq
    (** [s ++ s'] is sequence [s'] concatenated to [s]. *)

    (** {1 JSON values} *)

    type t
    (** The type for JSON values. *)

    type mem
    (** The type for JSON members. *)

    type el
    (** The type for JSON array elements. *)

    val null : t
    (** [null] is the JSON null value. *)

    val bool : bool -> t
    (** [bool b] is [b] as a JSON boolean value. *)

    val int : int -> t
    (** [int i] is [i] as a JSON number. *)

    val str : string -> t
    (** [str s] is [s] as a JSON string value. *)

    val el : t -> el seq
    (** [el v] is [v] as a JSON array element. *)

    val el_if : bool -> (unit -> t) -> el seq
    (** [el_if c v] is [el (v ())] if [c] is [true] and {!empty} otherwise. *)

    val arr : el seq -> t
    (** [arr els] is an array whose values are defined by the elements [els]. *)

    val mem : string -> t -> mem seq
    (** [mem n v] is an object member whose name is [n] and value is [v]. *)

    val mem_if : bool -> string -> (unit -> t) -> mem seq
    (** [mem_if c n v] is [mem n v] if [c] is [true] and {!empty} otherwise. *)

    val obj : mem seq -> t
    (** [obj mems] is an object whose members are [mems]. *)

    (** {1 Output} *)

    val buffer_add : Buffer.t -> t -> unit
    (** [buffer_add b j] adds the JSON value [j] to [b]. *)

    val to_string : t -> string
    (** [to_string j] is the JSON value [j] as a string. *)

    val output : out_channel -> t -> unit
    (** [output oc j] outputs the JSON value [j] on [oc]. *)
  end

  (** HTML generation. *)
  module Html : sig

    (** {1 Generation sequences} *)

    type 'a seq
    (** The type for sequences. *)

    val empty : 'a seq
    (** An empty sequence. *)

    val ( ++ ) : 'a seq -> 'a seq -> 'a seq
    (** [s ++ s'] is sequence [s'] concatenated to [s]. *)

    (** {1 HTML generation} *)

    type att
    (** The type for attributes. *)

    type attv
    (** The type for attribute values. *)

    type t
    (** The type for elements or character data. *)

    val attv : string -> attv seq
    (** [attv v] is an attribute value [v]. *)

    val att : string -> attv seq -> att seq
    (** [att a v] is an attribute [a] with value [v]. *)

    val data : string -> t seq
    (** [data d] is character data [d]. *)

    val el : string -> ?atts:att seq -> t seq -> t seq
    (** [el e ~atts c] is an element [e] with attribute
        [atts] and content [c]. *)

    (** {1 Derived attributes} *)

    val href : string -> att seq
    (** [href l] is an [href] attribute with value [l]. *)

    val id : string -> att seq
    (** [id i] is an [id] attribute with value [i]. *)

    val class_ : string -> att seq
    (** [class_ c] is a class attribute [c]. *)

    (** {1 Derived elements} *)

    val a : ?atts:att seq -> t seq -> t seq
    val link : ?atts:att seq -> string -> t seq -> t seq
    val div : ?atts:att seq -> t seq -> t seq
    val meta : ?atts:att seq -> t seq -> t seq
    val nav : ?atts:att seq -> t seq -> t seq
    val code : ?atts:att seq -> t seq -> t seq
    val ul : ?atts:att seq -> t seq -> t seq
    val ol : ?atts:att seq -> t seq -> t seq
    val li : ?atts:att seq -> t seq -> t seq
    val dl : ?atts:att seq -> t seq -> t seq
    val dt : ?atts:att seq -> t seq -> t seq
    val dd : ?atts:att seq -> t seq -> t seq
    val p : ?atts:att seq -> t seq -> t seq
    val h1 : ?atts:att seq -> t seq -> t seq
    val h2 : ?atts:att seq -> t seq -> t seq
    val span : ?atts:att seq -> t seq -> t seq
    val body : ?atts:att seq -> t seq -> t seq
    val html : ?atts:att seq -> t seq -> t seq

    (** {1 Output} *)

    val buffer_add : ?doc_type:bool -> Buffer.t -> t seq -> unit
    (** [buffer_add ~doc_type b h] adds the sequence [h] to [b].
        If [doc_type] is [true] (default) an HTML doctype declaration
        is prepended. *)

    val to_string : ?doc_type:bool -> t seq -> string
    (** [to_string] is like {!buffer_add} but returns
        directly a string. *)

    val output : ?doc_type:bool -> out_channel -> t seq -> unit
    (** [output] is like {!buffer_add} but outputs directly on
        a channel. *)
  end

  (** Dot graph generation.

    {b Note.} No support for ports. Should be too hard to add though.

    {b References}
    {ul
    {- {{:http://www.graphviz.org/content/dot-language}Dot language
       grammar}}} *)
  module Dot : sig

    (** {1 Generation sequences} *)

    type 'a seq
    (** The type for sequences. *)

    val empty : 'a seq
    (** An empty sequence. *)

    val ( ++ ) : 'a seq -> 'a seq -> 'a seq
    (** [s ++ s'] is sequence [s'] concatenated to [s]. *)

    (** {1 Graphs} *)

    type id = string
    (** The type for ids, they can be any string and are escaped. *)

    type st
    (** The type for dot statements. *)

    type att
    (** The type for dot attributes. *)

    type t
    (** The type for dot graphs. *)

    val edge : ?atts:att seq -> id -> id -> st seq
    (** [edge ~atts id id'] is an edge from [id] to [id'] with attribute
        [atts] if specified. *)

    val node : ?atts:att seq -> id -> st seq
    (** [nod ~atts id] is a node with id [id] and attributes [atts] if
        specified. *)

    val atts : [`Graph | `Node | `Edge] -> att seq -> st seq
    (** [atts kind atts] are attributes [atts] for [kind]. *)

    val att : string -> string -> att seq
    (** [att k v] is attribute [k] with value [v]. *)

    val label : string -> att seq
    (** [label l] is label attribute [l]. *)

    val color : string -> att seq
    (** [color c] is a color attribute [l]. *)

    val subgraph : ?id:id -> st seq -> st seq
    (** [subgraph ~id sts] is subgraph [id] (default unlabelled) with
        statements [sts]. *)

    val graph :
      ?id:id -> ?strict:bool -> [`Graph | `Digraph] -> st seq -> t
    (** [graph ~id ~strict g sts] is according to [g] a graph or digraph [id]
        (default unlabelled) with statements [sts]. If [strict] is [true]
        (defaults to [false]) multi-edges are not created. *)

    (** {1 Output} *)

    val buffer_add : Buffer.t -> t -> unit
    (** [buffer_add b g] adds the dot graph [g] to [b]. *)

    val to_string : t -> string
    (** [to_string g] is the dot graph [g] as a string. *)

    val output : out_channel -> t -> unit
    (** [output oc g] outputs the dot graph [g] on [oc]. *)
  end

  (** Digests. *)
  module Digest : sig

    (** {1 Digests} *)

    include module type of Digest

    val file : Fpath.t -> (t, [`Msg of string]) result
    (** [file f] is the digest of file [f]. *)

    val mtimes : Fpath.t list -> (t, [`Msg of string]) result
    (** [mtimes ps] is a digest of the mtimes of [ps]. The [ps] list
        sorted with {!Fpath.compare}. *)
  end

  (** Computation trails.

      {b Do not look at this}. *)
  module Trail : sig
    type t
    val pp_dot : root:Fpath.t -> t Fmt.t
    val pp_dot_universe : root:Fpath.t -> unit Fmt.t
  end

  (** Packages. *)
  module Pkg : sig

    include module type of Pkg
    with type t = Pkg.t
     and type set = Pkg.set
     and module Set = Pkg.Set
     and module Map = Pkg.Map

    val cobjs_trail : t -> Trail.t
    (** [cobjs_trail p] is a trail for {!Cobjs.t}. *)

    val install_trail : t -> Trail.t
    (** [install_trail p] is [p]'s install trail. If the install changes
        the trail's digest updates. *)
  end
end

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Daniel C. Bünzli

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
