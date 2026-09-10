#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Filename：mail_check.py
# Author：lizhengbei
# Contact：lizhengbei@gmail.com
# Created Time：2026-05-27 11:38:16
# Description：
# Copyright (C) 2026  Ltd. All rights reserved.
import imaplib
import ssl


def get_unseen_count_only(email_address, auth_code):
    # 1. 允许在 AUTH 状态下发送 ID 命令
    imaplib.Commands["ID"] = ("AUTH", "AUTHED", "SELECTED")

    imap_server = "imap.126.com"
    port = 993

    context = ssl.create_default_context()
    mail = imaplib.IMAP4_SSL(imap_server, port, ssl_context=context)

    try:
        # 2. 登录 (如果追求完美的纯数字输出，可以把下面的 print 注释掉)
        mail.login(email_address, auth_code)

        # 3. 发送伪装特征
        client_id_params = (
            '("name" "Foxmail" '
            '"version" "7.2.25.120" '
            '"os" "Windows" '
            '"os-version" "10.0" '
            '"vendor" "Tencent" '
            '"support-url" "http://gacc.mail.163.com")'
        )
        mail._simple_command("ID", client_id_params)

        # 状态回滚
        mail.state = "AUTH"

        # 4. 选择收件箱
        status, _ = mail.select("INBOX", readonly=True)
        if status != "OK":
            return

        # 5. 搜索未读邮件并只打印数字
        status, response_data = mail.search(None, "UNSEEN")
        if status == "OK":
            id_list = response_data[0].split()
            # 【核心】这里只打印纯数字
            print(len(id_list))

    except Exception as e:
        pass
    finally:
        try:
            mail.logout()
        except:
            pass


if __name__ == "__main__":
    USER_EMAIL = "@126.com"
    AUTH_CODE = ""

    get_unseen_count_only(USER_EMAIL, AUTH_CODE)
