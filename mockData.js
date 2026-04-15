const paymentIntentBody = {
  currency: "BRL",
  amount: 2999,
  installment_options: [
    {
      payment_method: "card",
      installments: [
        {
          number_of_installments: [5],
          billing_frequency: "month",
          interest_rate: 0,
        },
        {
          number_of_installments: [1, 3, 6, 12],
          billing_frequency: "month",
          interest_rate: 11.1,
        },
        {
          number_of_installments: [2, 4, 7, 11],
          billing_frequency: "month",
          interest_rate: 14.1,
        },
      ],
    },
  ],
  order_details: [
    {
      product_name: "Apple iPhone 15",
      quantity: 1,
      amount: 2999,
    },
  ],
  confirm: false,
  capture_method: "automatic",
  authentication_type: "three_ds",
  customer_id: "hyperswitch_sdk_demo_id",
  email: "hyperswitch_sdk_demo_id@gmail.com",
  request_external_three_ds_authentication: false,
  description: "Hello this is description",
  shipping: {
    address: {
      line1: "1467",
      line2: "Harrison Street",
      line3: "Harrison Street",
      city: "San Fransico",
      state: "California",
      zip: "94122",
      country: "US",
      first_name: "joseph",
      last_name: "Doe",
    },
    phone: {
      number: "8056594427",
      country_code: "+91",
    },
  },
  metadata: {
    udf1: "value1",
    new_customer: "true",
    login_date: "2019-09-10T10:11:12Z",
  },
  billing: {
    address: {
      line1: "1467",
      line2: "Harrison Street",
      line3: "Harrison Street",
      city: "San Fransico",
      state: "California",
      zip: "94122",
      country: "US",
      first_name: "joseph",
      last_name: "Doe",
    },
    phone: {
      number: "8056594427",
      country_code: "+91",
    },
  },
};

module.exports = {paymentIntentBody};
