# Events

## aTox.add-message

Adds a message

| Tag   | content                                  | required |
| :---: | :--------------------------------------- | :------: |
| cid   | The **CHAT** ID                          | yes      |
| tid   | The **TOX** ID (currently cid or -1)     | yes      |
| color | A valid CSS color string                 | yes      |
| name  | The name of the user sending the message | yes      |
| img   | Avatar                                   | no       |
| msg   | The message string                       | yes      |


## chat-visibility

| Tag   | content                                  | required |
| :---: | :--------------------------------------- | :------: |
| cid   | The **CHAT** ID                          | yes      |
| what  | What to do. *MUST* be 'hide' or 'show'   | yes      |

## notify

Sends a notification

| Tag     | content                         | required |
| :-----: | :------------------------------ | :------: |
| type    | The type (inf, warn, error)     | yes      |
| name    |                                 | yes      |
| content |                                 | yes      |
| img     | full path to an image           | no       |
