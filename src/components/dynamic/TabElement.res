@react.component
let make = (
  ~paymentMethodData: ClientResponseType.paymentMethodEnabled,
  ~isScreenFocus,
  ~processRequest,
  ~checkEligibility: option<string> => unit,
  ~setConfirmButtonData,
) => {
  let {
    formDataRef,
    getRequiredFieldsForTabs,
    country,
    isNicknameValid,
    setInitialValueCountry,
    eligibilityStatus,
  } = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  let (formData, setFormData) = React.useState(_ => Dict.make())
  let setFormData = React.useCallback1(data => {
    formDataRef->Option.map(ref => ref.current = data)->ignore
    setFormData(_ => data)
  }, [setFormData])

  let (isFormValid, setIsFormValid) = React.useState(_ => false)
  let setIsFormValid = React.useCallback1(isValid => {
    setIsFormValid(_ => isValid)
  }, [setIsFormValid])

  let (isPristine, setIsPristine) = React.useState(_ => true)
  let setIsPristine = React.useCallback1(pristine => {
    setIsPristine(_ => pristine)
  }, [setIsPristine])

  let (formMethods, setFormMethods) = React.useState(_ => None)
  let setFormMethods = React.useCallback1(formSubmit => {
    setFormMethods(_ => formSubmit)
  }, [setFormMethods])

  let notifyValidationFailure = UseWidgetActions.useNotifyValidationFailure()

  let (selectedInstallmentPlan, setSelectedInstallmentPlan) = React.useState(_ => None)
  let setSelectedInstallmentPlan = React.useCallback1(plan => {
    setSelectedInstallmentPlan(_ => plan)
  }, [setSelectedInstallmentPlan])

  let (showInstallments, setShowInstallments) = React.useState(_ => false)
  let setShowInstallments = React.useCallback1(show => {
    setShowInstallments(_ => show)
  }, [setShowInstallments])

  let (installmentsError, setInstallmentsError) = React.useState(_ => "")
  let setInstallmentsError = React.useCallback1(error => {
    setInstallmentsError(_ => error)
  }, [setInstallmentsError])

  // Opting into installments without picking a plan leaves the payment incomplete.
  let isInstallmentValid = !showInstallments || selectedInstallmentPlan->Option.isSome

  let (
    requiredFields,
    initialValues,
    isCardPayment,
    enabledCardSchemes,
    accessible,
    defaultCountry,
  ) = React.useMemo4(_ => {
    getRequiredFieldsForTabs(paymentMethodData, formData, isScreenFocus)
  }, (paymentMethodData.payment_method_type, getRequiredFieldsForTabs, country, isScreenFocus))

  let handlePress = _ => {
    // Only gate on eligibility for card payments; non-card methods skip the check
    let isEligibilityBlocked = isCardPayment && eligibilityStatus !== DynamicFieldsContext.Allowed
    if isEligibilityBlocked {
      ()
    } else if (
      isNicknameValid && isInstallmentValid && (isFormValid || requiredFields->Array.length === 0)
    ) {
      processRequest(
        CommonUtils.mergeDict(initialValues, formData),
        None,
        formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
        selectedInstallmentPlan,
      )
    } else {
      if !isInstallmentValid {
        setInstallmentsError(InstallmentStrings.selectPlanError)
      }
      switch formMethods {
      | Some(methods: ReactFinalForm.Form.formMethods) => methods.submit()
      | None => ()
      }
      notifyValidationFailure()
    }
  }

  // The block only makes sense once the BIN is known, and unmounting it resets the
  // whole installment selection.
  let cardBin =
    CommonUtils.mergeDict(initialValues, formData)
    ->Dict.get("payment_method_data")
    ->Option.flatMap(JSON.Decode.object)
    ->Option.mapOr([], Dict.valuesToArray)
    ->Array.filterMap(JSON.Decode.object)
    ->Array.filterMap(paymentMethodDict =>
      paymentMethodDict->Dict.get("card_number")->Option.flatMap(JSON.Decode.string)
    )
    ->Array.get(0)
    ->Option.getOr("")
    ->Validation.clearSpaces

  let installmentSection =
    cardBin->String.length >= 6
      ? <InstallmentOptions
          paymentMethod=paymentMethodData.payment_method_str
          setSelectedInstallmentPlan
          showInstallments
          setShowInstallments
          installmentsError
          setInstallmentsError
        />
      : React.null

  React.useEffect1(() => {
    setInitialValueCountry(defaultCountry)
    None
  }, [defaultCountry])

  FormStatusEmitter.useFormStatusEmitter(
    ~isFocused=isScreenFocus,
    ~hasRequiredFields=requiredFields->Array.length > 0,
    ~isFormValid,
    ~isPristine,
    ~isAdditionalValid=isInstallmentValid,
  )

  React.useEffect(() => {
    if isScreenFocus {
      let confirmButton = {
        GlobalConfirmButton.loading: false,
        handlePress,
        payment_method_type: paymentMethodData.payment_method_type,
        payment_experience: paymentMethodData.payment_experience,
        errorText: installmentsError === "" ? None : Some(installmentsError),
      }
      setConfirmButtonData(confirmButton)
    }
    None
  }, (
    paymentMethodData.payment_method_type,
    isScreenFocus,
    setConfirmButtonData,
    eligibilityStatus,
    requiredFields,
    isFormValid,
    formData,
    formMethods,
    isNicknameValid,
    selectedInstallmentPlan,
    showInstallments,
    installmentsError,
  ))

  <DynamicFields
    fields=requiredFields
    initialValues
    setFormData
    setIsFormValid
    setIsPristine=?Some(setIsPristine)
    setFormMethods
    isCardPayment
    enabledCardSchemes
    accessible
    isFocused=isScreenFocus
    checkEligibility
    installmentSection
  />
}
