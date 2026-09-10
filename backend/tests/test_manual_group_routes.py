import unittest
from unittest.mock import patch

from flask import Flask
import experiment_routes as routes
import experiment_service as service


class ManualGroupRouteTests(unittest.TestCase):
    def setUp(self):
        app = Flask(__name__)
        app.register_blueprint(routes.experiment_bp, url_prefix='/data')
        self.client = app.test_client()

    def test_profile_passes_explicit_mode_and_returns_updated_progress(self):
        with patch.object(routes, 'is_db_configured', return_value=True), patch.object(
            routes, 'update_participant_profile', return_value={'training_mode': 'audio'}
        ) as update:
            response = self.client.patch('/data/participants/me', json={
                'client_install_id': 'qa-install', 'training_mode': 'audio'})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json['training_mode'], 'audio')
        self.assertEqual(update.call_args.args, ('qa-install',))
        self.assertEqual(update.call_args.kwargs['training_mode'], 'audio')

    def test_invalid_mode_returns_400_without_database_access(self):
        with patch.object(routes, 'is_db_configured', return_value=True), patch.object(
            service, 'get_connection'
        ) as connection:
            response = self.client.patch('/data/participants/me', json={
                'client_install_id': 'qa-install', 'training_mode': 'unknown'})
        self.assertEqual(response.status_code, 400)
        connection.assert_not_called()
