from .base import PageObject


class PriceOption(PageObject):
    def select_platinum_price_option(self) -> None:
        self._page_title_should_be("Select Price Option")
        self._click("#selectplatinum + span")
        self._click("#nextsendquote")
