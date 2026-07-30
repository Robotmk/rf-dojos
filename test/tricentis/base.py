from robot.libraries.BuiltIn import BuiltIn


class PageObject:
    ROBOT_LIBRARY_SCOPE = "SUITE"

    @staticmethod
    def _run(keyword: str, *args):
        return BuiltIn().run_keyword(keyword, *args)

    def _fill(self, locator: str, value: str) -> None:
        self._run("Fill Text", locator, value)

    def _select_by_label(self, locator: str, label: str) -> None:
        self._run("Select Options By", locator, "label", label)

    def _select_by_value(self, locator: str, value: str) -> None:
        self._run("Select Options By", locator, "value", value)

    def _click(self, locator: str) -> None:
        self._run("Click", locator)

    def _page_title_should_be(self, expected: str) -> None:
        actual = self._run("Get Title")
        BuiltIn().should_be_equal(actual, expected)
