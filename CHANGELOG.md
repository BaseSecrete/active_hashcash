# Changelog of ActiveHashcash

## [Unreleased]

- Increase complexity logarithmicly to slowdown brute force attacks
- Store stamps into the database instead of Redis
- Fix ActiveHashcash::Store#add? by converting stamp to a string

## 0.2.0 - 2022-08-02

- Add ActiveHashcash::Store#clean to removed expired stamps

## [0.1.1] - 2022-07-08

- Fix when hashcash param is nil

## [0.1.0] - 2022-07-01

- Initial release
