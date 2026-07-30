from calendar import monthrange
from datetime import date, timedelta

from .base import PageObject


class Product(PageObject):
    def get_start_date_more_than_one_month_in_the_future(self) -> str:
        today = date.today()
        year = today.year + (today.month == 12)
        month = today.month % 12 + 1
        day = min(today.day, monthrange(year, month)[1])
        start_date = date(year, month, day) + timedelta(days=1)
        return start_date.strftime("%m/%d/%Y")

    def enter_product_data(
        self,
        start_date: str,
        insurance_sum: str,
        damage_insurance: str,
    ) -> None:
        self._page_title_should_be("Enter Product Data")
        self._fill("#startdate", start_date)
        self._select_by_value("#insurancesum", insurance_sum)
        self._select_by_label("#damageinsurance", damage_insurance)
        self._click("#EuroProtection + span")
        self._click("#nextselectpriceoption")
