Roger Sneakpeek
============

Upload current release to the Sneakpeek preview server.

## Installation
* Add ```gem 'roger_sneakpeek'``` to your Gemfile

* Add this to your Mockupfile:
```
mockup.release do |r|
  r.finalize :sneakpeek,
    project: "PROJECT_NAME",
    gitlab_project: GITLAB_NAMESPACE_AND_PROJECT,
    ci_only: false, # Only set this if you want to upload sneakpeek from your dev machine
end
```

## License

This project is released under the [MIT license](LICENSE).
