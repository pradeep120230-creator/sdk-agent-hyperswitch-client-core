@react.component
let make = (
  ~paymentMethodData: AccountPaymentMethodType.payment_method_type,
  ~isScreenFocus,
  ~processRequest,
  ~checkEligibility: option<string> => unit,
  ~setConfirmButtonData,
  ~installmentPlans: array<AccountPaymentMethodType.installmentPlan>=[],
  ~currency: string="",
  ~installmentDataRef: React.ref<option<PaymentConfirmTypes.installment_data>>=React.useRef(None),
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

  let localeObject = GetLocale.useGetLocalObj()
  let notifyValidationFailure = UseWidgetActions.useNotifyValidationFailure()

  let hasInstallmentPlans = installmentPlans->Array.length > 0
  let (showInstallments, setShowInstallments) = React.useState(_ => false)
  let (selectedInstallmentPlan, setSelectedInstallmentPlan): (
    option<AccountPaymentMethodType.installmentPlan>,
    (option<AccountPaymentMethodType.installmentPlan> => option<AccountPaymentMethodType.installmentPlan>) => unit,
  ) = React.useState(_ => None)
  let (installmentsError, setInstallmentsError) = React.useState(_ => None)

  React.useEffect0(() => {
    Some(() => {
      setShowInstallments(_ => false)
      setSelectedInstallmentPlan(_ => None)
      setInstallmentsError(_ => None)
    })
  })

  let isInstallmentValid =
    !hasInstallmentPlans || !showInstallments || selectedInstallmentPlan->Option.isSome

  let installmentDataForBody = if hasInstallmentPlans && showInstallments {
    selectedInstallmentPlan->Option.map((
      plan: AccountPaymentMethodType.installmentPlan,
    ): PaymentConfirmTypes.installment_data => {
      number_of_installments: plan.number_of_installments,
      billing_frequency: plan.billing_frequency,
    })
  } else {
    None
  }

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
    let isEligibilityBlocked = isCardPayment && eligibilityStatus !== DynamicFieldsContext.Allowed
    if isEligibilityBlocked {
      ()
    } else if !isInstallmentValid {
      setInstallmentsError(_ => Some(localeObject.installmentSelectPlanError))
      notifyValidationFailure()
    } else if isNicknameValid && (isFormValid || requiredFields->Array.length === 0) {
      setInstallmentsError(_ => None)
      installmentDataRef.current = installmentDataForBody
      processRequest(
        CommonUtils.mergeDict(initialValues, formData),
        None,
        formData->Dict.get("email")->Option.mapOr(None, JSON.Decode.string),
      )
    } else {
      switch formMethods {
      | Some(methods: ReactFinalForm.Form.formMethods) => methods.submit()
      | None => ()
      }
      notifyValidationFailure()
    }
  }

  React.useEffect1(() => {
    setInitialValueCountry(defaultCountry)
    None
  }, [defaultCountry])

  FormStatusEmitter.useFormStatusEmitter(
    ~isFocused=isScreenFocus,
    ~hasRequiredFields=requiredFields->Array.length > 0,
    ~isFormValid,
    ~isPristine,
  )

  React.useEffect(() => {
    if isScreenFocus {
      let confirmButton = {
        GlobalConfirmButton.loading: false,
        handlePress,
        payment_method_type: paymentMethodData.payment_method_type,
        payment_experience: paymentMethodData.payment_experience,
        errorText: None,
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
  ))

  <>
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
    />
    {hasInstallmentPlans && isCardPayment
      ? <InstallmentOptions
          installmentPlans
          currency
          selectedPlan=selectedInstallmentPlan
          setSelectedPlan=setSelectedInstallmentPlan
          showInstallments
          setShowInstallments
          errorText=installmentsError
        />
      : React.null}
  </>
}
