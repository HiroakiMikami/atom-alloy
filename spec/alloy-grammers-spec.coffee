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
  it "tokenizes signatures", ->
    lines = grammar.tokenizeLines """
    /* block comment */
    sig X, Y extends Base {
      foo: Bar //< line comment
    }"""
    expect(lines[0][0]).toEqual value: "/*", scopes: [
      "source.alloy",
      "comment.block.alloy"
    ]
    expect(lines[0][1]).toEqual value: " block comment ", scopes: [
      "source.alloy",
      "comment.block.alloy"
    ]
    expect(lines[0][2]).toEqual value: "*/", scopes: [
      "source.alloy",
      "comment.block.alloy"
    ]
    expect(lines[1][0]).toEqual value: "sig", scopes: [
      "source.alloy",
      "meta.declaration.signature.alloy",
      "storage.type.signature.alloy"
    ]
    expect(lines[1][1]).toEqual value: " ", scopes: [
      "source.alloy",
      "meta.declaration.signature.alloy"
    ]
    expect(lines[1][2]).toEqual value: "X", scopes: [
      "source.alloy",
      "meta.declaration.signature.alloy",
      "entity.name.type.signature.alloy"
    ]
    expect(lines[1][3]).toEqual value: ",", scopes: [
      "source.alloy",
      "meta.declaration.signature.alloy",
      "punctuation.declaration.separator.alloy"
    ]
    expect(lines[1][4]).toEqual value: " ", scopes: [
      "source.alloy",
      "meta.declaration.signature.alloy"
    ]
    expect(lines[1][5]).toEqual value: "Y", scopes: [
      "source.alloy",
      "meta.declaration.signature.alloy",
      "entity.name.type.signature.alloy"
    ]
    expect(lines[1][6]).toEqual value: " ", scopes: [
      "source.alloy"
      "meta.declaration.signature.alloy",
    ]
    expect(lines[1][7]).toEqual value: "extends", scopes: [
      "source.alloy",
      "meta.declaration.signature.alloy",
      "keyword.other.extends.alloy"
    ]
    expect(lines[1][8]).toEqual value: " ", scopes: [
      "source.alloy"
      "meta.declaration.signature.alloy",
    ]
    expect(lines[1][9]).toEqual value: "Base", scopes: [
      "source.alloy",
      "meta.declaration.signature.alloy",
      "entity.other.inherited-class.alloy"
    ]
    expect(lines[1][10]).toEqual value: " ", scopes: [
      "source.alloy",
      "meta.declaration.signature.alloy",
    ]
    expect(lines[1][11]).toEqual value: "{", scopes: [
      "source.alloy",
      "meta.block.alloy",
      "punctuation.block.begin.alloy"
    ]
    expect(lines[2][0]).toEqual value: "  ", scopes: [
      "source.alloy",
      "meta.block.alloy"
    ]
    expect(lines[2][1]).toEqual value: "foo", scopes: [
      "source.alloy",
      "meta.block.alloy",
      "meta.signature.name.alloy"
    ]
    expect(lines[2][2]).toEqual value: ": ", scopes: [
      "source.alloy",
      "meta.block.alloy"
    ]
    expect(lines[2][3]).toEqual value: "Bar", scopes: [
      "source.alloy",
      "meta.block.alloy",
      "meta.signature.name.alloy"
    ]
    expect(lines[2][4]).toEqual value: " ", scopes: [
      "source.alloy",
      "meta.block.alloy"
    ]
    expect(lines[2][5]).toEqual value: "//", scopes: [
      "source.alloy",
      "meta.block.alloy"
      "comment.line.double-slash.alloy"
    ]
    expect(lines[2][6]).toEqual value: "< line comment", scopes: [
      "source.alloy",
      "meta.block.alloy"
      "comment.line.double-slash.alloy"
    ]
    expect(lines[3][0]).toEqual value: "}", scopes: [
      "source.alloy",
      "meta.block.alloy",
      "punctuation.block.end.alloy"
    ]
