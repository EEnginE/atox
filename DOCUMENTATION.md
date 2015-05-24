# aTox - bot protocol

Options:

| Option | Meaning   |
| :----: | --------- |
|  *R*   | required  |
|  *O*   | optional  |
|  *D*   | default   |

## authenticate

###### Client sends:

```json
{
  "cmd":   "auth <[R]>",
  "prot":  "<protocol / service [O, D='GitHub']>",
  "name":  "<username [R]>",
  "token": "<access token [R]>"
}
```

###### Bot responds:

```json
{
  "cmd":     "auth <[R]>",
  "success": "<bool>",
  "name":    "<username [R]>",
  "token":   "<token [R]>"
}
```

## joining chats / creating chats

###### Client sends:

```json
{
  "cmd":  "chat <[R]>",
  "name": "<chat name [R]>"
}
```

###### Bot responds:

```json
{
  "cmd": "chat <[R]>",
  "err": "create / list / redirect",
  "list": [
    "<member list>"
  ],
  "redirect": "bot ID",
  "name":     "<chat name [R]>"
}
```

## chat list request

###### Bot sends:

```json
{
  "cmd":  "list <[R]>",
  "id":   "<request ID (number) [R]>"
}
```

###### Client responds:

```json
{
  "cmd":  "list <[R]>",
  "id":   "<request ID (number) [R]>",
  "list": [
    "<chat names>"
  ]
}
```

## ping

Should only be sent *once* after connecting / reconnecting to a bot

###### Client sends:

```json
{
  "cmd": "ping <[R]>",
  "Pv":  "<client protocol version [R]>"
}
```

###### Bot responds:

```json
{
  "cmd": "ping <[R]>",
  "Pv":  "<bot protocol version [R]>"
}
```


# aTox - aTox protocol

## ping

Should only be sent *once* after connecting / reconnecting to a client.

###### Client sends:

```json
{
  "cmd": "ping <[R]>",
  "Pv":  "<client protocol version [R]>"
}
```

###### Other client responds:

```json
{
  "cmd": "ping <[R]>",
  "Pv":  "<client protocol version [R]>"
}
```

## invite request

###### Client sends:

```json
{
  "cmd":  "invite <[R]>",
  "name": "<chat name [R]>"
}
```

###### Other client responds:

```json
{
  "cmd":  "invite <[R]>",
  "name": "<chat name [R]>",
  "err":  "sent / unknown chat"
}
```
