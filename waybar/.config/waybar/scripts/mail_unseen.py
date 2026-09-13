#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：mail_unseen.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-27 11:49:09
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
#!/usr/bin/env python3
import imaplib
import json
import ssl


def get_waybar_json():
    # ==================== 填入你的信息 ====================
    USER_EMAIL = ""
    AUTH_CODE = ""  # 16位授权码
    # ====================================================

    imaplib.Commands["ID"] = ("AUTH", "AUTHED", "SELECTED")
    imap_server = "imap.126.com"
    port = 993
    context = ssl.create_default_context()

    try:
        mail = imaplib.IMAP4_SSL(imap_server, port, ssl_context=context)
        mail.login(USER_EMAIL, AUTH_CODE)

        # 绕过风控
        client_id_params = '("name" "Foxmail" "version" "7.2.25.120" "os" "Windows" "os-version" "10.0" "vendor" "Tencent")'
        mail._simple_command("ID", client_id_params)
        mail.state = "AUTH"

        status, _ = mail.select("INBOX", readonly=True)
        if status != "OK":
            raise Exception("Select failed")

        status, response_data = mail.search(None, "UNSEEN")

        if status == "OK":
            id_list = response_data[0].split()
            count = len(id_list)

            # ================= 复刻你的 jq 逻辑 =================
            if count == 0:
                output = {
                    "text": "󰻧 ",
                    "alt": "none",
                    "class": "none",
                    "tooltip": "没有未读邮件",
                }
            else:
                output = {
                    "text": f"󰻩 {count}",
                    "alt": "has-email",
                    "class": "has-email",
                    "tooltip": f"当前有 {count} 条未读邮件",
                }
            print(json.dumps(output))

        mail.logout()

    except Exception:
        # 出错时优雅降级
        print(
            json.dumps(
                {
                    "text": "󰅸 !",
                    "alt": "error",
                    "class": "error",
                    "tooltip": "邮件检查失败",
                }
            )
        )


if __name__ == "__main__":
    get_waybar_json()
