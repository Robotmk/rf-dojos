from .base import PageObject


class Insurant(PageObject):
    def enter_insurant_data(
        self,
        first_name: str,
        last_name: str,
        birth_date: str,
        street_address: str,
        postal_code: str,
        city: str,
        country: str,
        occupation: str,
    ) -> None:
        self._page_title_should_be("Enter Insurant Data")
        self._fill("#firstname", first_name)
        self._fill("#lastname", last_name)
        self._fill("#birthdate", birth_date)
        self._click("#gendermale + span")
        self._fill("#streetaddress", street_address)
        self._select_by_label("#country", country)
        self._fill("#zipcode", postal_code)
        self._fill("#city", city)
        self._select_by_label("#occupation", occupation)
        self._click("#bungeejumping + span")
        self._click("#nextenterproductdata")
