type authorizationResponse = {
  approved: bool,
  showForm: bool,
  finalizeRequired: bool,
  authorizationToken: option<string>,
  clientToken: option<string>,
  sessionId: option<string>,
  collectedShippingAddress: option<string>,
  merchantReference1: option<string>,
  merchantReference2: option<string>,
}

type errorResponse = {
  name: string,
  message: string,
  isFatal: bool,
  sessionId: option<string>,
}

type finalizeResult = {
  approved: bool,
  showForm: bool,
  finalizeRequired: bool,
  authorizationToken: option<string>,
  clientToken: option<string>,
  sessionId: option<string>,
  collectedShippingAddress: option<string>,
  merchantReference1: option<string>,
  merchantReference2: option<string>,
  errorName: option<string>,
  errorMessage: option<string>,
  isFatal: option<bool>,
}

type module_ = {
  isAvailable: bool,
  finalize: (string, finalizeResult => unit) => unit,
}

@val external require: string => module_ = "require"

let mod = try {
  require("@juspay-tech/react-native-hyperswitch-klarna-expresscheckout")->Some
} catch {
| _ => None
}

let isAvailable = switch mod {
| Some(m) => m.isAvailable
| None => false
}

let finalize = (clientToken: string, callback: finalizeResult => unit) => {
  switch mod {
  | Some(m) =>
    try {
      m.finalize(clientToken, callback)
    } catch {
    | _ => ()
    }
  | None => ()
  }
}
