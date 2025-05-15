# Changelog of ActiveHashcash

## 0.4.0 (2025-05-15)

- Prevent from password managers to submit the form before the stamp has been computed
- Added support for the "button" submit form tag
- Added Catalan language
- Added `base_controller_class` configuration option to allow specifying a custom base controller for the ActiveHashcash dashboard, enhancing flexibility in diverse application architectures.

## 0.3.2 (2024-08-29)

- Fix methods conflict by not including ActionView::Helpers::FormTagHelper
- Sanitize params by forcing as a String

## 0.3.1 - 2024-04-04

- Fix gem spec list files

## 0.3.0 - 2024-03-14

- Increase complexity automatically to slowdown brute force attacks
- Add mountable dashboard to list latest stamps and most frequent IP addresses
- Store stamps into the database instead of Redis
- Fix ActiveHashcash::Store#add? by converting stamp to a string

## 0.2.0 - 2022-08-02

- Add ActiveHashcash::Store#clean to removed expired stamps

## [0.1.1] - 2022-07-08

- Fix when hashcash param is nil

## [0.1.0] - 2022-07-01

- Initial release
