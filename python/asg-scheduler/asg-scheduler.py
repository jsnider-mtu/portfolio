# -*- coding: utf-8 -*-
import boto3
import logging
import os
import uuid

from datetime import datetime

from flask import (
    Flask,
    redirect,
    render_template,
    request,
    session,
    url_for,
)
from flask_login import (
    LoginManager,
    UserMixin,
    current_user,
    login_required,
    login_user,
    logout_user,
)
from flask_bootstrap import Bootstrap
from saml2 import (
    BINDING_HTTP_POST,
    BINDING_HTTP_REDIRECT,
    entity,
)
from saml2.client import Saml2Client
from saml2.config import Config as Saml2Config
import requests

# metadata_url_for contains PER APPLICATION configuration settings.
# Each SAML service that you support will have different values here.
#
# NOTE:
#   This is implemented as a dictionary for DEMONSTRATION PURPOSES ONLY.
#   On a production system, this information should be stored as approprate
#   for your concept of "customer company", "group", "organization", or "team"
metadata_url_for = {
    # For testing with http://saml.oktadev.com use the following:
    # 'test': 'http://idp.oktadev.com/metadata',
    # WARNING WARNING WARNING
    #   You MUST remove the testing IdP from a production system,
    #   as the testing IdP will allow ANYBODY to log in as ANY USER!
    # WARNING WARNING WARNING
    "test": "http://idp.oktadev.com/metadata"
}

app = Flask(__name__)
Bootstrap(app)
app.secret_key = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
login_manager = LoginManager()
login_manager.setup_app(app)
logging.basicConfig(level=logging.INFO)
# NOTE:
#   This is implemented as a dictionary for DEMONSTRATION PURPOSES ONLY.
#   On a production system, this information must come
#   from your system's user store.
user_store = {}
rv = None


def saml_client_for(idp_name=None):
    """
    Given the name of an IdP, return a configuation.
    The configuration is a hash for use by saml2.config.Config
    """

    if idp_name not in metadata_url_for:
        raise Exception("Settings for IDP '{}' not found".format(idp_name))
    acs_url = url_for("idp_initiated", idp_name=idp_name, _external=True)
    https_acs_url = url_for(
        "idp_initiated", idp_name=idp_name, _external=True, _scheme="https"
    )

    #   SAML metadata changes very rarely. On a production system,
    #   this data should be cached as approprate for your production system.
    global rv
    if not rv:
        rv = requests.get(metadata_url_for[idp_name])

    settings = {
        "entityid": "ASGScheduler",
        "metadata": {
            "inline": [rv.text],
        },
        "service": {
            "sp": {
                "endpoints": {
                    "assertion_consumer_service": [
                        (acs_url, BINDING_HTTP_REDIRECT),
                        (acs_url, BINDING_HTTP_POST),
                        (https_acs_url, BINDING_HTTP_REDIRECT),
                        (https_acs_url, BINDING_HTTP_POST),
                    ],
                },
                # Don't verify that the incoming requests originate from us via
                # the built-in cache for authn request ids in pysaml2
                "allow_unsolicited": True,
                # Don't sign authn requests, since signed requests only make
                # sense in a situation where you control both the SP and IdP
                "authn_requests_signed": False,
                "logout_requests_signed": True,
                "want_assertions_signed": True,
                "want_response_signed": False,
            },
        },
    }
    spConfig = Saml2Config()
    spConfig.load(settings)
    spConfig.allow_unknown_attributes = True
    saml_client = Saml2Client(config=spConfig)
    return saml_client


class User(UserMixin):
    def __init__(self, user_id):
        user = {}
        self.id = None
        self.first_name = None
        self.last_name = None
        try:
            user = user_store[user_id]
            self.id = unicode(user_id)
            self.first_name = user["first_name"]
            self.last_name = user["last_name"]
        except:
            pass


def getEvents():
    client = boto3.client("autoscaling", region_name="us-east-1")
    return client.describe_scheduled_actions(
        AutoScalingGroupName="jsnider-mtu-asg", MaxRecords=20
    )


def putEvent(eventTime, eventName, desiredCapacity):
    client = boto3.client("autoscaling", region_name="us-east-1")
    return client.put_scheduled_update_group_action(
        AutoScalingGroupName="jsnider-mtu-asg",
        ScheduledActionName=eventName,
        StartTime=eventTime,
        MinSize=int(desiredCapacity),
    )


@login_manager.user_loader
def load_user(user_id):
    return User(user_id)


@app.route("/", methods=["GET", "POST"])
def main_page():
    err = ""
    submittedDateTime = ""
    submittedEventName = ""
    if request.method == "POST":
        formDate = request.form["date"]
        formTime = request.form["time"]
        formEventName = request.form["eventName"]
        desiredCapacity = request.form["desiredCapacity"]
        if not formEventName:
            submittedEventName = "Invalid event name"
            err = "Event name is required"
        elif not desiredCapacity:
            err = "Desired capacity is required"
        elif not formDate:
            submittedDateTime = "Invalid date"
            err = "Date is required"
        elif not formTime:
            submittedDateTime = "Invalid time"
            err = "Time in UTC is required"
        elif (
            datetime.strptime(formDate + " " + formTime, "%Y-%m-%d %H:%M")
            < datetime.now()
        ):
            submittedDateTime = "Invalid date and time"
            err = "Date and time cannot be in the past"
        else:
            submittedDateTime = "".join([str(formDate), "T", str(formTime), ":00Z"])
            submittedEventName = formEventName.replace(" ", "-")
            try:
                putEvent(submittedDateTime, submittedEventName, desiredCapacity)
            except Exception as e:
                err = e
    data = getEvents()
    return render_template(
        "main_page.html",
        error=err,
        idp_dict=metadata_url_for,
        data=data["ScheduledUpdateGroupActions"],
        submittedDateTime=submittedDateTime,
        submittedEventName=submittedEventName,
    )


@app.route("/saml/sso/<idp_name>", methods=["GET", "POST"])
def idp_initiated(idp_name):
    if request.method == "GET":
        url = url_for("main_page", _external=True)
        return redirect(url)
    saml_client = saml_client_for(idp_name)
    authn_response = saml_client.parse_authn_request_response(
        request.form["SAMLResponse"], entity.BINDING_HTTP_POST
    )
    authn_response.get_identity()
    user_info = authn_response.get_subject()
    username = user_info.text

    # This is what as known as "Just In Time (JIT) provisioning".
    # What that means is that, if a user in a SAML assertion
    # isn't in the user store, we create that user first, then log them in
    if username not in user_store:
        user_store[username] = {
            "first_name": authn_response.ava["FirstName"][0],
            "last_name": authn_response.ava["LastName"][0],
        }
    user = User(username)
    session["saml_attributes"] = authn_response.ava
    login_user(user)
    url = url_for("user")
    # NOTE:
    #   On a production system, the RelayState MUST be checked
    #   to make sure it doesn't contain dangerous URLs!
    if "RelayState" in request.form:
        url = request.form["RelayState"]
    return redirect(url)


@app.route("/saml/login/<idp_name>")
def sp_initiated(idp_name):
    saml_client = saml_client_for(idp_name)
    reqid, info = saml_client.prepare_for_authenticate()

    redirect_url = None
    # Select the IdP URL to send the AuthN request to
    for key, value in info["headers"]:
        if key == "Location":
            redirect_url = value
    response = redirect(redirect_url, code=302)
    # NOTE:
    #   I realize I _technically_ don't need to set Cache-Control or Pragma:
    #     http://stackoverflow.com/a/5494469
    #   However, Section 3.2.3.2 of the SAML spec suggests they are set:
    #     http://docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf
    #   We set those headers here as a "belt and suspenders" approach,
    #   since enterprise environments don't always conform to RFCs
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    return response


@app.route("/user")
@login_required
def user():
    return render_template("user.html", session=session)


@app.errorhandler(401)
def error_unauthorized(error):
    return render_template("unauthorized.html")


@app.route("/logout")
@login_required
def logout():
    logout_user()
    return redirect(url_for("main_page"))


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    if port == 5000:
        app.debug = True
    app.run(host="0.0.0.0", port=port)
