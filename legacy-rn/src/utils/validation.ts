export const emailRules = {
  required: 'Email is required',
  pattern: {
    value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
    message: 'Invalid email address',
  },
};

export const passwordRules = {
  required: 'Password is required',
  minLength: {
    value: 6,
    message: 'Password must be at least 6 characters',
  },
};

export const nameRules = {
  required: 'Full name is required',
  minLength: {
    value: 2,
    message: 'Name must be at least 2 characters',
  },
};

export const firstNameRules = {
  required: 'First name is required',
  minLength: {
    value: 2,
    message: 'First name must be at least 2 characters',
  },
};

export const lastNameRules = {
  required: 'Last name is required',
  minLength: {
    value: 1,
    message: 'Last name must be at least 1 character',
  },
};

export const phoneRules = {
  required: 'Phone number is required',
  pattern: {
    value: /^\+?[1-9]\d{1,14}$/,
    message: 'Invalid phone number (use E.164 format, e.g. +919876543210)',
  },
};
