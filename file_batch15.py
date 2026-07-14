#!/usr/bin/env python3
"""File all 25 Batch 15 recordings to their destination Drive folders and mark done."""
import json
import sys
sys.path.insert(0, '/home/ubuntu/recordings_pipeline')

from googleapiclient.discovery import build
from google.oauth2 import service_account

# Load service account
SA_FILE = '/home/ubuntu/recordings_pipeline/service_account.json'
SCOPES = ['https://www.googleapis.com/auth/drive']
creds = service_account.Credentials.from_service_account_file(SA_FILE, scopes=SCOPES)
drive = build('drive', 'v3', credentials=creds)

# Folder IDs from profiles.json
FOLDERS = {
    'Inbox': '1R8aP1YFqaiojFAqVBFDj-n0-rGhmAav9',
    'Gerald': '1fIUVHUWlTUChkJLlj5K-XrPHPm5wn9qP',
    'Ethan': '18rfNjyj7XaC7E7fHR6u3JFj1Qq1_o4St',
    'Personal Notes': '1Bw1F45StcpM8UPm6vMc14Q5pFZ_18oI7',
    'Other': '1vIdE78TJrPDIb9tI7N1uotgfNH1T75sH',
}

# Filing manifest: (drive_file_id, destination_folder)
MANIFEST = [
    # Silent/ambient -> Other
    ('1KT35A5vfTXx6ohpa60u_Al8h-PfXBOMP', 'Other'),   # 06-09-14-15-54
    ('16A8kwJY3MfNx1o4EnyxyST00ARjp8A9h', 'Other'),   # 06-09-15-15-55
    ('1UxyH7e-ZzPIF1d7jKXXRSGJJXBRnQpoy', 'Other'),   # 06-09-16-15-55
    ('19PFU9trM3YJhxlCVQYAYGeAJn1bbwXsx', 'Other'),   # 06-09-17-04-25
    ('1l6Q4o6vg_XJdmIkOQBFT-iW97BYQViX4', 'Other'),   # 06-09-17-41-40
    ('1K82CdShj47Nq-qWz_r0qGrwURKXMADXK', 'Other'),   # 06-09-18-11-58
    ('1piJtmifkp4pUIFi-FyibZR7rWcgJRVei', 'Other'),   # 06-10-08-38-32
    ('1YeLzrnrQ5H_6lsWzEiQYBrVfVkgaG4Sw', 'Other'),   # 06-10-09-43-28
    ('1tinySqRuI9jnQ6jyqH2yuUGkp8_PpI3j', 'Other'),   # 06-10-10-44-35
    ('1j9LAq81s7Sl1WAYNDHz3DQBPGy-DQL3T', 'Other'),   # 06-10-14-31-43
    # Work conversation -> Ethan
    ('1JwCZEYOyvtlA97ueZvTHcz9o5kDCB_Co', 'Ethan'),   # 06-10-14-45-44
    # Silent -> Other
    ('1q3hMyiHrhntaKlqUpwfWBUTjnUsPWJfK', 'Other'),   # 06-10-15-45-44
    ('1FxN95CX6qfYT9sK8_Abr8yYEQGKGc-be', 'Other'),   # 06-10-16-45-44
    ('1xH-YliIqO5EFxBEMuUdZCj-dZLxyxr-7', 'Other'),   # 06-10-22-05-52
    ('1OUUH83DKUXf6oz295aT_5hKXwAmq1oXh', 'Other'),   # 06-11-13-29-25
    ('1hxizBHAst1IrFayGDtxxbHsX5FNi4rZy', 'Other'),   # 06-11-13-29-32
    # Personal -> Personal Notes
    ('1o2OmtvY47ov9uZbcL-EuYF4ZSxW80fz9', 'Personal Notes'),  # 06-11-14-20-50 restaurant
    ('1S85eN5j67Dp4qU2beTn-ZNcYydbSsuWG', 'Personal Notes'),  # 06-11-14-26-00 parking
    # Empty -> Other
    ('1M5jO1HB1AjrhLp41nAFbGbv1hJq3p09C', 'Other'),   # 06-11-14-31-43
    ('1u9thBBb8nd61JM7b41-lLX41s2wmzu0b', 'Other'),   # 06-11-14-32-47
    # Gerald business call -> Gerald
    ('1DF02jT-s1AHI9WtCy4WHmxnMmrHPjVUg', 'Gerald'),  # 06-11-22-00-51
    # Drug pickup -> Personal Notes
    ('1bZKsKittR63mDsNr3ttefqfM_FLxceDu', 'Personal Notes'),  # 06-11-23-47-38
    # Music -> Other
    ('1NAJIlQk0gOaDCbp4IftYhzyFiyfznDlt', 'Other'),   # 06-12-00-52-12
    ('18-XHQdipiIBlECEIMT45KvUh5pUKjQHK', 'Other'),   # 06-12-01-29-11
    # Vet call -> Personal Notes
    ('17Pe2moBBvYSslU79uWKUXmig2YNlDM_2', 'Personal Notes'),  # 06-12-11-21-06
]

# Load processed state
import os
STATE_FILE = '/home/ubuntu/recordings_pipeline/processed_state.json'
with open(STATE_FILE) as f:
    state = json.load(f)

moved = 0
failed = 0
inbox_id = FOLDERS['Inbox']

for file_id, dest_name in MANIFEST:
    dest_id = FOLDERS[dest_name]
    try:
        # Get current parents
        meta = drive.files().get(fileId=file_id, fields='name,parents').execute()
        fname = meta.get('name', file_id)
        parents = meta.get('parents', [])
        
        # Move: add new parent, remove old parents
        drive.files().update(
            fileId=file_id,
            addParents=dest_id,
            removeParents=','.join(parents),
            fields='id,parents'
        ).execute()
        
        print(f'MOVED: {fname} -> {dest_name}')
        
        # Mark done in state
        state['processed_ids'] = state.get('processed_ids', [])
        if file_id not in state['processed_ids']:
            state['processed_ids'].append(file_id)
        
        moved += 1
    except Exception as e:
        print(f'FAILED: {file_id} -> {dest_name}: {e}')
        failed += 1

# Save state
with open(STATE_FILE, 'w') as f:
    json.dump(state, f, indent=2)

print(f'\nDone: {moved} moved, {failed} failed')
