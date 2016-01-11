describe "Alloy grammar", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("atom-alloy")

    runs ->
      grammar = atom.grammars.grammarForScopeName("source.alloy")

  it "parses the grammar", ->
    expect(grammar).toBeDefined()
    expect(grammar.scopeName).toBe "source.alloy"
  it "tokenizes a module declaration", ->
    {tokens} = grammar.tokenizeLine("module foo/bar")
    expect(tokens[0]).toEqual value: "module", scopes: ["source.alloy", "meta.module.alloy", "storage.type.module.alloy"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.alloy", "meta.module.alloy"]
    expect(tokens[2]).toEqual value: "foo/bar", scopes: ["source.alloy", "meta.module.alloy", "meta.module.name.alloy"]

    {tokens} = grammar.tokenizeLine("module foo/bar [K, V]")
    expect(tokens[0]).toEqual value: "module", scopes: ["source.alloy", "meta.module.alloy", "storage.type.module.alloy"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.alloy", "meta.module.alloy"]
    expect(tokens[2]).toEqual value: "foo/bar", scopes: ["source.alloy", "meta.module.alloy", "meta.module.name.alloy"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.alloy", "meta.module.alloy"]
    expect(tokens[4]).toEqual value: "[", scopes: [
      "source.alloy"
      "meta.module.alloy"
      "punctuation.type-parameters.begin.alloy"
    ]
    expect(tokens[5]).toEqual value: "K", scopes: [
      "source.alloy",
      "meta.module.alloy",
      "meta.type-parameter.name.alloy"
    ]
    expect(tokens[6]).toEqual value: ",", scopes: [
      "source.alloy",
      "meta.module.alloy"
      "punctuation.type-parameters.separator.alloy"
    ]
    expect(tokens[7]).toEqual value: " ", scopes: [
      "source.alloy",
      "meta.module.alloy"
    ]
    expect(tokens[8]).toEqual value: "V", scopes: [
      "source.alloy",
      "meta.module.alloy",
      "meta.type-parameter.name.alloy"
    ]
    expect(tokens[9]).toEqual value: "]", scopes: [
      "source.alloy"
      "meta.module.alloy"
      "punctuation.type-parameters.end.alloy"
    ]
  it "tokenizes import statements", ->
    {tokens} = grammar.tokenizeLine("open foo/bar as f")
    expect(tokens[0]).toEqual value: "open", scopes: ["source.alloy", "meta.import.alloy", "keyword.other.open.alloy"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.alloy", "meta.import.alloy"]
    expect(tokens[2]).toEqual value: "foo/bar", scopes: ["source.alloy", "meta.import.alloy", "meta.module.name.alloy"]
    expect(tokens[3]).toEqual value: " ", scopes: ["source.alloy", "meta.import.alloy"]
    expect(tokens[4]).toEqual value: "as", scopes: ["source.alloy", "meta.import.alloy", "keyword.other.as.alloy"]
    expect(tokens[5]).toEqual value: " ", scopes: ["source.alloy", "meta.import.alloy"]
    expect(tokens[6]).toEqual value: "f", scopes: ["source.alloy", "meta.import.alloy", "meta.module.name.alloy"]

    {tokens} = grammar.tokenizeLine("open foo/bar[K, V]")
    expect(tokens[0]).toEqual value: "open", scopes: ["source.alloy", "meta.import.alloy", "keyword.other.open.alloy"]
    expect(tokens[1]).toEqual value: " ", scopes: ["source.alloy", "meta.import.alloy"]
    expect(tokens[2]).toEqual value: "foo/bar", scopes: ["source.alloy", "meta.import.alloy", "meta.module.name.alloy"]
    expect(tokens[3]).toEqual value: "[", scopes: [
      "source.alloy",
      "meta.import.alloy",
      "punctuation.type-parameters.begin.alloy"
    ]
    expect(tokens[4]).toEqual value: "K", scopes: [
      "source.alloy",
      "meta.import.alloy",
      "meta.type-parameter.name.alloy"
    ]
    expect(tokens[5]).toEqual value: ",", scopes: [
      "source.alloy",
      "meta.import.alloy"
      "punctuation.type-parameters.separator.alloy"
    ]
    expect(tokens[6]).toEqual value: " ", scopes: [
      "source.alloy",
      "meta.import.alloy"
    ]
    expect(tokens[7]).toEqual value: "V", scopes: [
      "source.alloy",
      "meta.import.alloy",
      "meta.type-parameter.name.alloy"
    ]
    expect(tokens[8]).toEqual value: "]", scopes: [
      "source.alloy"
      "meta.import.alloy"
      "punctuation.type-parameters.end.alloy"
    ]
