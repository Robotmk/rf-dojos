from .base import PageObject


class Home(PageObject):
    URL = "https://sampleapp.tricentis.com/101/"

    def open_landing_page(self) -> None:
        self._run("New Page", self.URL)
        self._page_title_should_be("Tricentis Vehicle Insurance")

    def start_truck_insurance_quote(self) -> None:
        self._click("css=a#nav_truck:visible")
        self._page_title_should_be("Enter Vehicle Data")
