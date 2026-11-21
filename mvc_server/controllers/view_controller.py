import json
import os
from controllers.analytics_controller import AnalyticsController


class ViewController:
    """Controller layer binding SQL Model snapshot into MVC HTML View templates."""

    def __init__(self, analytics_controller: AnalyticsController, views_dir: str):
        self.analytics_controller = analytics_controller
        self.views_dir = views_dir

    def render_dashboard(self) -> tuple[int, str]:
        _, initial_data = self.analytics_controller.dashboard_data()
        tpl_path = os.path.join(self.views_dir, "dashboard.html")
        with open(tpl_path, "r", encoding="utf-8") as f:
            html = f.read()
        html = html.replace("__INITIAL_DATA_JSON__", json.dumps(initial_data, ensure_ascii=False))
        return 200, html
