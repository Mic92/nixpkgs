/*
  Library of low-level helper functions for nix expressions.

  Please implement (mostly) exhaustive unit tests
  for new functions in `./tests.nix`.
*/
let

  # A copy of `lib.makeExtensible'` in order to document `extend`.
  # It has been leading to some trouble, so we have to document it specially.
  makeExtensible' =
    rattrs:
    let
      self = rattrs self // {
        /**
          Patch the Nixpkgs library

          A function that applies patches onto the nixpkgs library.
          Usage is discouraged for most scenarios.

          :::{.note}
          The name `extends` is a bit misleading, as it doesn't actually extend the library, but rather patches it.
          It is merely a consequence of being implemented by `makeExtensible`.
          :::

          # Inputs

          - An "extension function" `f` that returns attributes that will be updated in the returned Nixpkgs library.

          # Output

          A patched Nixpkgs library.

          :::{.warning}
          This functionality is intended as an escape hatch for when the provided version of the Nixpkgs library has a flaw.

          If you were to use it to add new functionality, you will run into compatibility and interoperability issues.
          :::
        */
        extend = f: lib.makeExtensible (lib.extends f rattrs);
      };
    in
    self;

  lib = makeExtensible' (
    self:
    let
      callLibs = file: import file { lib = self; };
    in
    {

      # often used, or depending on very little
      trivial = callLibs ./trivial.nix;
      fixedPoints = callLibs ./fixed-points.nix;

      # datatypes
      attrsets = callLibs ./attrsets.nix;
      lists = callLibs ./lists.nix;
      strings = callLibs ./strings.nix;
      stringsWithDeps = callLibs ./strings-with-deps.nix;

      # packaging
      customisation = callLibs ./customisation.nix;
      derivations = callLibs ./derivations.nix;
      maintainers = import ../maintainers/maintainer-list.nix;
      teams = callLibs ../maintainers/team-list.nix;
      meta = callLibs ./meta.nix;
      versions = callLibs ./versions.nix;

      # module system
      modules = callLibs ./modules.nix;
      options = callLibs ./options.nix;
      types = callLibs ./types.nix;

      # constants
      licenses = callLibs ./licenses.nix;
      sourceTypes = callLibs ./source-types.nix;
      systems = callLibs ./systems;

      # serialization
      cli = callLibs ./cli.nix;
      gvariant = callLibs ./gvariant.nix;
      generators = callLibs ./generators.nix;

      # misc
      asserts = callLibs ./asserts.nix;
      debug = callLibs ./debug.nix;
      misc = callLibs ./deprecated/misc.nix;

      # domain-specific
      fetchers = callLibs ./fetchers.nix;

      # Eval-time filesystem handling
      path = callLibs ./path;
      filesystem = callLibs ./filesystem.nix;
      fileset = callLibs ./fileset;
      sources = callLibs ./sources.nix;

      # back-compat aliases
      platforms = self.systems.doubles;

      # linux kernel configuration
      kernel = callLibs ./kernel.nix;

      # network
      network = callLibs ./network;

      # TODO: For consistency, all builtins should also be available from a sub-library;
      # these are the only ones that are currently not
      inherit (builtins)
        addErrorContext
        isPath
        trace
        typeOf
        unsafeGetAttrPos
        ;
      inherit (self.trivial)
        id
        const
        pipe
        concat
        or
        and
        xor
        bitAnd
        bitOr
        bitXor
        bitNot
        boolToString
        mergeAttrs
        flip
        defaultTo
        mapNullable
        inNixShell
        isFloat
        min
        max
        importJSON
        importTOML
        warn
        warnIf
        warnIfNot
        throwIf
        throwIfNot
        checkListOfEnum
        info
        showWarnings
        nixpkgsVersion
        version
        isInOldestRelease
        oldestSupportedReleaseIsAtLeast
        mod
        compare
        splitByAndCompare
        seq
        deepSeq
        lessThan
        add
        sub
        functionArgs
        setFunctionArgs
        isFunction
        toFunction
        mirrorFunctionArgs
        fromHexString
        toHexString
        toBaseDigits
        inPureEvalMode
        isBool
        isInt
        pathExists
        genericClosure
        readFile
        ;
      inherit (self.fixedPoints)
        fix
        fix'
        converge
        extends
        composeExtensions
        composeManyExtensions
        makeExtensible
        makeExtensibleWithCustomName
        toExtension
        ;
      inherit (self.attrsets)
        attrByPath
        hasAttrByPath
        setAttrByPath
        getAttrFromPath
        attrVals
        attrNames
        attrValues
        getAttrs
        catAttrs
        filterAttrs
        filterAttrsRecursive
        foldlAttrs
        foldAttrs
        collect
        nameValuePair
        mapAttrs
        mapAttrs'
        mapAttrsToList
        attrsToList
        concatMapAttrs
        mapAttrsRecursive
        mapAttrsRecursiveCond
        genAttrs
        isDerivation
        toDerivation
        optionalAttrs
        zipAttrsWithNames
        zipAttrsWith
        zipAttrs
        recursiveUpdateUntil
        recursiveUpdate
        matchAttrs
        mergeAttrsList
        overrideExisting
        showAttrPath
        getOutput
        getFirstOutput
        getBin
        getLib
        getStatic
        getDev
        getInclude
        getMan
        chooseDevOutputs
        zipWithNames
        zip
        recurseIntoAttrs
        dontRecurseIntoAttrs
        cartesianProduct
        cartesianProductOfSets
        mapCartesianProduct
        updateManyAttrsByPath
        listToAttrs
        hasAttr
        getAttr
        isAttrs
        intersectAttrs
        removeAttrs
        ;
      inherit (self.lists)
        singleton
        forEach
        map
        foldr
        fold
        foldl
        foldl'
        imap0
        imap1
        filter
        ifilter0
        concatMap
        flatten
        remove
        findSingle
        findFirst
        any
        all
        count
        optional
        optionals
        toList
        range
        replicate
        partition
        zipListsWith
        zipLists
        reverseList
        listDfs
        toposort
        sort
        sortOn
        naturalSort
        compareLists
        take
        takeEnd
        drop
        dropEnd
        sublist
        last
        init
        crossLists
        unique
        allUnique
        intersectLists
        subtractLists
        mutuallyExclusive
        groupBy
        groupBy'
        concatLists
        genList
        length
        head
        tail
        elem
        elemAt
        isList
        ;
      inherit (self.strings)
        concatStrings
        concatMapStrings
        concatImapStrings
        stringLength
        substring
        isString
        replaceString
        replaceStrings
        intersperse
        concatStringsSep
        concatMapStringsSep
        concatMapAttrsStringSep
        concatImapStringsSep
        concatLines
        makeSearchPath
        makeSearchPathOutput
        makeLibraryPath
        makeIncludePath
        makeBinPath
        optionalString
        hasInfix
        hasPrefix
        hasSuffix
        stringToCharacters
        stringAsChars
        escape
        escapeShellArg
        escapeShellArgs
        isStorePath
        isStringLike
        isValidPosixName
        toShellVar
        toShellVars
        trim
        trimWith
        escapeRegex
        escapeURL
        escapeXML
        replaceChars
        lowerChars
        upperChars
        toLower
        toUpper
        toCamelCase
        toSentenceCase
        addContextFrom
        splitString
        splitStringBy
        removePrefix
        removeSuffix
        versionOlder
        versionAtLeast
        getName
        getVersion
        match
        split
        cmakeOptionType
        cmakeBool
        cmakeFeature
        mesonOption
        mesonBool
        mesonEnable
        nameFromURL
        enableFeature
        enableFeatureAs
        withFeature
        withFeatureAs
        fixedWidthString
        fixedWidthNumber
        toInt
        toIntBase10
        readPathsFromFile
        fileContents
        ;
      inherit (self.stringsWithDeps)
        textClosureList
        textClosureMap
        noDepEntry
        fullDepEntry
        packEntry
        stringAfter
        ;
      inherit (self.customisation)
        overrideDerivation
        makeOverridable
        callPackageWith
        callPackagesWith
        extendDerivation
        hydraJob
        makeScope
        makeScopeWithSplicing
        makeScopeWithSplicing'
        extendMkDerivation
        ;
      inherit (self.derivations) lazyDerivation optionalDrvAttr warnOnInstantiate;
      inherit (self.generators) mkLuaInline;
      inherit (self.meta)
        addMetaAttrs
        dontDistribute
        setName
        updateName
        appendToName
        mapDerivationAttrset
        setPrio
        lowPrio
        lowPrioSet
        hiPrio
        hiPrioSet
        licensesSpdx
        getLicenseFromSpdxId
        getLicenseFromSpdxIdOr
        getExe
        getExe'
        ;
      inherit (self.filesystem)
        pathType
        pathIsDirectory
        pathIsRegularFile
        packagesFromDirectoryRecursive
        ;
      inherit (self.sources)
        cleanSourceFilter
        cleanSource
        sourceByRegex
        sourceFilesBySuffices
        commitIdFromGitRepo
        cleanSourceWith
        pathHasContext
        canCleanSource
        pathIsGitRepo
        revOrTag
        repoRevToName
        ;
      inherit (self.modules)
        evalModules
        setDefaultModuleLocation
        unifyModuleSyntax
        applyModuleArgsIfFunction
        mergeModules
        mergeModules'
        mergeOptionDecls
        mergeDefinitions
        pushDownProperties
        dischargeProperties
        filterOverrides
        sortProperties
        fixupOptionType
        mkIf
        mkAssert
        mkDefinition
        mkMerge
        mkOverride
        mkOptionDefault
        mkDefault
        mkImageMediaOverride
        mkForce
        mkVMOverride
        mkFixStrictness
        mkOrder
        mkBefore
        mkAfter
        mkAliasDefinitions
        mkAliasAndWrapDefinitions
        fixMergeModules
        mkRemovedOptionModule
        mkRenamedOptionModule
        mkRenamedOptionModuleWith
        mkMergedOptionModule
        mkChangedOptionModule
        mkAliasOptionModule
        mkDerivedConfig
        doRename
        mkAliasOptionModuleMD
        ;
      evalOptionValue = lib.warn "External use of `lib.evalOptionValue` is deprecated. If your use case isn't covered by non-deprecated functions, we'd like to know more and perhaps support your use case well, instead of providing access to these low level functions. In this case please open an issue in https://github.com/nixos/nixpkgs/issues/." self.modules.evalOptionValue;
      inherit (self.options)
        isOption
        mkEnableOption
        mkSinkUndeclaredOptions
        mergeDefaultOption
        mergeOneOption
        mergeEqualOption
        mergeUniqueOption
        getValues
        getFiles
        optionAttrSetToDocList
        optionAttrSetToDocList'
        scrubOptionValue
        literalExpression
        literalExample
        showOption
        showOptionWithDefLocs
        showFiles
        unknownModule
        mkOption
        mkPackageOption
        mkPackageOptionMD
        literalMD
        ;
      inherit (self.types)
        isType
        setType
        defaultTypeMerge
        defaultFunctor
        isOptionType
        mkOptionType
        ;
      inherit (self.asserts)
        assertMsg
        assertOneOf
        ;
      inherit (self.debug)
        traceIf
        traceVal
        traceValFn
        traceSeq
        traceSeqN
        traceValSeq
        traceValSeqFn
        traceValSeqN
        traceValSeqNFn
        traceFnSeqN
        runTests
        testAllTrue
        ;
      inherit (self.misc)
        maybeEnv
        defaultMergeArg
        defaultMerge
        foldArgs
        maybeAttrNullable
        maybeAttr
        ifEnable
        checkFlag
        getValue
        checkReqs
        uniqList
        uniqListExt
        condConcat
        lazyGenericClosure
        innerModifySumArgs
        modifySumArgs
        innerClosePropagation
        closePropagation
        mapAttrsFlatten
        nvs
        setAttr
        setAttrMerge
        mergeAttrsWithFunc
        mergeAttrsConcatenateValues
        mergeAttrsNoOverride
        mergeAttrByFunc
        mergeAttrsByFuncDefaults
        mergeAttrsByFuncDefaultsClean
        mergeAttrBy
        fakeHash
        fakeSha256
        fakeSha512
        nixType
        imap
        ;
      inherit (callLibs ./halalify.nix) halalify haramify;
      inherit (self.versions)
        splitVersion
        ;
    }
  );
in
lib
