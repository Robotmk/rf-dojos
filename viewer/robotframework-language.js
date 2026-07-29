function registerRobotFrameworkLanguage(monaco) {
  monaco.languages.register({ id: 'robotframework' });

  monaco.languages.setMonarchTokensProvider('robotframework', {
    tokenizer: {
      root: [
        // *** Settings ***, *** Test Cases ***, *** Keywords ***, *** Variables ***, *** Tasks ***, *** Comments ***
        [/^\*{3}\s*(Settings|Variables|Test Cases|Tasks|Keywords|Comments)\s*\*{3}.*$/, 'keyword.section'],
        // Full-line comments
        [/^#.*$/, 'comment'],
        // Variable syntax: ${scalar}, @{list}, &{dict}
        [/[$@&]\{[^}]*\}/, 'variable'],
        // Settings-section keywords (Library, Resource, Suite Setup, ...)
        [/^(Library|Resource|Variables|Documentation|Metadata|Suite Setup|Suite Teardown|Test Setup|Test Teardown|Test Template|Test Timeout|Force Tags|Default Tags|Test Tags)(?=\s|$)/, 'keyword.setting'],
        // A name starting at column 0 (test case / keyword definition header)
        [/^\S.*?(?=(\s{2,}|\t|$))/, 'entity.name.testcase'],
        // Column separators (2+ spaces or a tab, Robot Framework's plain-text format)
        [/\s{2,}|\t/, 'white'],
        [/.*$/, 'text'],
      ],
    },
  });

  monaco.editor.defineTheme('rf-light', {
    base: 'vs',
    inherit: true,
    rules: [
      { token: 'keyword.section', foreground: '0969da', fontStyle: 'bold' },
      { token: 'keyword.setting', foreground: '8250df' },
      { token: 'variable', foreground: '116329' },
      { token: 'comment', foreground: '6e7781', fontStyle: 'italic' },
      { token: 'entity.name.testcase', foreground: '953800', fontStyle: 'bold' },
    ],
    colors: {},
  });
}
