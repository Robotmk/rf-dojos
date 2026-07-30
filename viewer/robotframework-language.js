function registerRobotFrameworkLanguage(monaco) {
  monaco.languages.register({ id: 'robotframework' });

  monaco.languages.setMonarchTokensProvider('robotframework', {
    tokenizer: {
      root: [
        // *** Settings ***, *** Test Cases ***, *** Keywords ***, *** Variables ***, *** Tasks ***, *** Comments ***
        [/^\*{3}\s*(Settings|Variables|Test Cases|Tasks|Keywords|Comments)\s*\*{3}.*$/, 'keyword.section'],
        // Comments - both full-line (column 0) and indented/trailing ones,
        // which are the overwhelmingly common form inside test cases/keywords.
        [/#.*$/, 'comment'],
        // Test-case/keyword-level settings, e.g. [Documentation], [Tags],
        // [Setup], [Teardown], [Arguments], [Return]. Checked before the
        // generic column-0 name rule below so these don't get mis-tokenized
        // as test case/keyword names.
        [/^\s*\[[A-Za-z ]+\]/, 'keyword.setting'],
        // Variable syntax: ${scalar}, @{list}, &{dict}
        [/[$@&]\{[^}]*\}/, 'variable'],
        // Settings-section keywords (Library, Resource, Suite Setup, ...)
        [/^(Library|Resource|Variables|Documentation|Metadata|Suite Setup|Suite Teardown|Test Setup|Test Teardown|Test Template|Test Timeout|Force Tags|Default Tags|Test Tags)(?=\s|$)/, 'keyword.setting'],
        // A name starting at column 0 (test case / keyword definition header)
        [/^\S.*?(?=(\s{2,}|\t|$))/, 'entity.name.testcase'],
        // Column separators (2+ spaces or a tab, Robot Framework's plain-text format)
        [/\s{2,}|\t/, 'white'],
        // Rest-of-cell text. Stops before a '#' (instead of greedily eating
        // to end of line) so a trailing comment on the same line still gets
        // picked up by the comment rule above on the next tokenizer pass.
        [/[^#]+/, 'text'],
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

  monaco.editor.defineTheme('rf-dark', {
    base: 'vs-dark',
    inherit: true,
    rules: [
      { token: 'keyword.section', foreground: '58a6ff', fontStyle: 'bold' },
      { token: 'keyword.setting', foreground: 'd2a8ff' },
      { token: 'variable', foreground: '7ee787' },
      { token: 'comment', foreground: '8b949e', fontStyle: 'italic' },
      { token: 'entity.name.testcase', foreground: 'ffa657', fontStyle: 'bold' },
    ],
    colors: {
      'editor.background': '#0d1117',
    },
  });
}
