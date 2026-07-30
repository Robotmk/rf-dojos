from robot.libraries.BuiltIn import BuiltIn

from .base import PageObject


class Quote(PageObject):
    SUCCESS_MESSAGE = "Sending e-mail success!"

    def send_quote(
        self,
        email: str,
        phone: str,
        username: str,
        password: str,
        comment: str,
    ) -> None:
        self._page_title_should_be("Send Quote")
        self._fill("#email", email)
        self._fill("#phone", phone)
        self._fill("#username", username)
        self._fill("#password", password)
        self._fill("#confirmpassword", password)
        self._fill("#Comments", comment)
        self._click("#sendemail")

    def quote_should_be_sent_successfully(self) -> None:
        locator = "css=.sweet-alert h2"
        self._run("Wait For Elements State", locator, "visible", "30s")
        actual = self._run("Get Text", locator)
        BuiltIn().should_be_equal(actual, self.SUCCESS_MESSAGE)
