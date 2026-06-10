import logging
import subprocess
import re
from shutil import which
from pathlib import Path
import gi
gi.require_version("Gio", "2.0")
gi.require_version("Gtk", "3.0")
from gi.repository import Gio, Gtk  # type: ignore
from ulauncher.api.client.Extension import Extension
from ulauncher.api.client.EventListener import EventListener
from ulauncher.api.shared.event import KeywordQueryEvent
from ulauncher.api.shared.item.ExtensionResultItem import ExtensionResultItem
from ulauncher.api.shared.action.RenderResultListAction import RenderResultListAction
from ulauncher.api.shared.action.RunScriptAction import RunScriptAction

logger = logging.getLogger(__name__)

class QuickFind2Extension(Extension):
    fd_available = which("fd") is not None
    icon_theme = None
    cached_folder_icon = None

    def __init__(self):
        super().__init__()
        self.subscribe(KeywordQueryEvent, KeywordQueryEventListener())
        if QuickFind2Extension.icon_theme is None:
            QuickFind2Extension.icon_theme = Gtk.IconTheme.get_default()
        if QuickFind2Extension.cached_folder_icon is None:
            QuickFind2Extension.cached_folder_icon = QuickFind2Extension.get_folder_icon()

    @staticmethod
    def find(pattern: str, path: str, extra: str, max_results: int) -> list[str]:
        tokens = pattern.strip().split()
        if not tokens:
            return []

        regex = ".*".join(map(re.escape, tokens))
        cmd = ["fd", "-a", "-c", "never", "--max-results", str(max_results)] + extra.split() + [regex]
        result = subprocess.run(cmd, cwd=path, capture_output=True, text=True)
        return result.stdout.splitlines()

    @staticmethod
    def get_folder_icon(size: int = 32) -> str:
        import tempfile
        temp_dir = tempfile.gettempdir()
        icon = QuickFind2Extension.get_system_icon(temp_dir, size)
        return icon if icon else "images/folder.svg"

    @staticmethod
    def get_system_icon(path: str, size: int = 32) -> str:
        try:
            file = Gio.File.new_for_path(path)
            file_info = file.query_info("standard::icon", Gio.FileQueryInfoFlags.NONE, None)
            icon = file_info.get_icon()
            
            if hasattr(icon, "get_names"):
                icon_names = icon.get_names()
            else:
                icon_names = [icon.to_string()]
            
            for icon_name in icon_names:
                icon_info = QuickFind2Extension.icon_theme.lookup_icon(icon_name, size, 0)  # type: ignore (is not None)
                if icon_info:
                    filename = icon_info.get_filename()
                    if filename:
                        return filename
        except Exception as e:
            logger.warning(f"Failed to get icon for {path}: {e}")
        return ""
    
    @staticmethod
    def get_default_icon(path: str) -> str:
        if Path(path).is_dir():
            return "images/folder.svg"
        return "images/file.svg"

    @staticmethod
    def return_item(path: str, query_icons: bool) -> ExtensionResultItem:
        ppath = Path(path)

        icon = ""
        if query_icons:
            icon = QuickFind2Extension.get_system_icon(path)
        if not icon:
            icon = QuickFind2Extension.get_default_icon(path)
            
        return ExtensionResultItem(
            icon = icon,
            name = ppath.name,
            description = str(ppath.parent),
            on_enter = RunScriptAction(f'xdg-open "{path}"', []),
            on_alt_enter = RunScriptAction(f'xdg-open "{str(ppath.parent)}"', []))

    @staticmethod
    def return_error(message: str) -> RenderResultListAction:
        return RenderResultListAction([
            ExtensionResultItem(
                icon="images/error.svg",
                name = "Error",
                description = message)])

class KeywordQueryEventListener(EventListener):

    def on_event(self, event: KeywordQueryEvent, extension: Extension) -> RenderResultListAction:  # type: ignore[override]
        
        if not QuickFind2Extension.fd_available:
            logger.error("fd is not installed")
            return QuickFind2Extension.return_error("fd is not installed")

        pattern = event.get_argument()
        if not pattern or pattern.strip() == "":
            return RenderResultListAction([])
        
        keyword = event.get_keyword()

        key_files = extension.preferences.get("key_files", "ff")
        key_folders = extension.preferences.get("key_folders", "fo")
        search_path = str(Path(extension.preferences.get("search_path", "~")).expanduser())
        fd_options = extension.preferences.get("fd_options", "--hidden")
        num_results = int(extension.preferences.get("num_results", "10"))
        query_icons = extension.preferences.get("query_icons", "yes") == "yes"

        if keyword == key_files:
            extra = f"{fd_options} -t f"
        elif keyword == key_folders:
            extra = f"{fd_options} -t d"
        else:
            return RenderResultListAction([])
        
        results = QuickFind2Extension.find(pattern, search_path, extra, num_results)
        return RenderResultListAction([
            QuickFind2Extension.return_item(result, query_icons) for result in results])
    
if __name__ == "__main__":
    QuickFind2Extension().run()
