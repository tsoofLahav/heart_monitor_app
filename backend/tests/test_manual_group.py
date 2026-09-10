"""External-QA group selection; no live database is used."""
import unittest
from unittest.mock import MagicMock, patch

import experiment_service as service


class ManualGroupTests(unittest.TestCase):
    def connection(self, rows):
        context = MagicMock()
        cursor = context.__enter__.return_value.cursor.return_value
        cursor.fetchone.side_effect = rows
        return context, cursor

    def test_new_install_defaults_to_regular(self):
        context, cursor = self.connection([None, (42,), (9,), ('P001', 'real')])
        with patch.object(service, 'get_connection', return_value=context), patch.object(
            service, '_next_participant_code', return_value='P001'
        ):
            result = service.bootstrap_participant('new-install')
        inserts = [call.args for call in cursor.execute.call_args_list
                   if 'INSERT INTO Participants' in call.args[0]]
        self.assertEqual(inserts[0][1:], ('new-install', 'P001', 'real'))
        self.assertEqual(result['training_mode'], 'ppg')

    def test_existing_control_assignment_is_restored(self):
        context, cursor = self.connection([(42,)])
        saved = {'training_mode': 'audio', 'trial_id': 9}
        with patch.object(service, 'get_connection', return_value=context), patch.object(
            service, '_load_progress', return_value=saved
        ):
            self.assertEqual(service.bootstrap_participant('existing-install'), saved)
        self.assertFalse(any('INSERT' in call.args[0] for call in cursor.execute.call_args_list))

    def test_profile_can_switch_both_directions_without_resetting_trial(self):
        for mode, condition in [('audio', 'control'), ('ppg', 'real')]:
            with self.subTest(mode=mode):
                context, cursor = self.connection([(42,)])
                saved = {'training_mode': mode, 'trial_id': 9, 'current_session': 3}
                with patch.object(service, 'get_connection', return_value=context), patch.object(
                    service, '_load_progress', return_value=saved
                ):
                    result = service.update_participant_profile('install', training_mode=mode)
                cursor.execute.assert_any_call(
                    'UPDATE Participants SET Condition = ? WHERE Id = ?', condition, 42)
                self.assertEqual(result, saved)
                self.assertFalse(any('DELETE' in call.args[0] or 'UPDATE Trials' in call.args[0]
                                     for call in cursor.execute.call_args_list))

    def test_invalid_group_is_rejected_before_any_write(self):
        for mode in ['real', 'control', '', 'other', 4, []]:
            with self.subTest(mode=mode), patch.object(service, 'get_connection') as connection:
                with self.assertRaises(ValueError):
                    service.update_participant_profile('install', training_mode=mode)
                connection.assert_not_called()

    def test_old_profile_request_does_not_change_group(self):
        context, cursor = self.connection([(42,)])
        with patch.object(service, 'get_connection', return_value=context), patch.object(
            service, '_load_progress', return_value={'training_mode': 'audio'}
        ):
            service.update_participant_profile('install', phone='0500000000')
        self.assertFalse(any('SET Condition' in call.args[0] for call in cursor.execute.call_args_list))


if __name__ == '__main__':
    unittest.main()
