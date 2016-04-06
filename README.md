[![Build Status](https://img.shields.io/travis/theodi/open-data-certificate.svg)](https://travis-ci.org/theodi/open-data-certificate)
[![Dependency Status](https://img.shields.io/gemnasium/theodi/open-data-certificate.svg)](https://gemnasium.com/theodi/open-data-certificate)
[![Coverage Status](https://img.shields.io/coveralls/theodi/open-data-certificate.svg)](https://coveralls.io/r/theodi/open-data-certificate)
[![Code Climate](https://img.shields.io/codeclimate/github/theodi/open-data-certificate.svg)](https://codeclimate.com/github/theodi/open-data-certificate)
[![License](https://img.shields.io/github/license/theodi/open-data-certificate.svg)](http://theodi.mit-license.org/)
[![Badges](https://img.shields.io/:badges-6/6-ff6799.svg)](https://github.com/badges/badgerbadgerbadger)

## ODI Open Data Certificate

### License

This code is open source under the MIT license. See the LICENSE.md file for
full details.


### Running

#### Under Docker

1. Install [Docker Toolbox](https://www.docker.com/products/docker-toolbox)
2. run `bin/dockerize`
3. make tea
4. everything should be set up and be open in your browser.

Tests can be run inside a container too with:

    docker-compose run web bundle exec rake test

#### In a traditional dev environment

```bash
# this will setup a default admin user (test@example.com) and
# load the GB survey
bin/setup
bundle exec rails s

# to include some other jurisdictions
rake surveyor:build_changed_surveys LIMIT=5
```

This will give you a default login of test@example.com/testtest.


### API

Certificates can be created and updated using the JSON API.

The API methods are:

- GET `/jurisdictions` - This method provides a list of the available jurisdictions and associated information
- GET `/datasets/schema` - This method provides the list of questions, their types and possible choices. You must specify your jurisdiction by title with the `jurisdiction` GET parameter
- POST `/datasets` - This method allows you to create a new dataset, it will be automatically published if valid
- POST `/datasets/:id/certificates` - This method allows you to update a dataset, it will be automatically published if valid


#### Authentication

Each user can access their API token from their account page. This token is required to authenticate with the API.
The request should authenticated with Basic HTTP Authentication, using the user's email address as the username and token as the password i.e. `john@example.com:ad54965ec45d78ab6f`.

#### Questionnaire schema

The schema method returns a hash where each question is identified by its key in the hash. Each question also has one of
the following types: `string`, `radio`, `checkbox` and `repeating`. Radio and checkbox types will also have an options hash,
which specifies the allowed options, which should be identified by their key.

Questions which are required to publish the dataset will also have `required: true`.

An example:

    {"schema": {
        "dataTitle": {
            "question": "What's a good title for this data?",
            "type": "string",
            "required": true
        },
        "publisherRights": {
            "question": "Do you have the rights to publish the data as open data?",
            "type": "radio",
            "required": true,
            "options": {
                "yes": "yes, you have the right to publish the data as open data",
                "no": "no, you don't have the right to publish the data as open data",
                "unsure": "you don't know whether you have the right to publish the data as open data"
            }
        },
        "versionManagement": {
            "question": "How do you publish a series of the same dataset?",
            "type": "checkbox",
            "required": false,
            "options": {
                "url": "as a single URL",
                "consistent": "as consistent URLs for each release",
                "list": "as a list of releases"
            }
        },
        "administrators": {
            "question": "Who is responsible for administrating this data?",
            "type": "repeating",
            "required": false
        }
    }}

#### Posting to a dataset

To create or update a dataset data should be sent in the format (using the above schema):

    {
        "jurisdiction": "GB",
        "dataset": {
            "dataTitle": "My open data",
            "publisherRights": "unsure",
            "versionManagement": ["url", "list"],
            "administrators": ["John Smith"]
        }
    }


- Checkbox and radio fields should use the option key from the schema
- Checkbox and repeating fields should be sent as an array

The request should contain a Content-Type header with the value `application/json`.

If your request has a `documentationUrl`, the system will attempt to use
that dataset's metadata (for example: if it is hosted in a [CKAN](http://ckan.org/)
repository or marked up with [DCAT](http://theodi.org/guides/marking-up-your-dataset-with-dcat))
to autocomplete as many questions as possible.

You will then get a response in this format:

    {
      "success": "pending",
      "dataset_id": 123,
      "dataset_url": "http://certificates.theodi.org/datasets/123.json"
    }

You can then make a request to the `dataset_url` to get the final response.
There may be a delay before your dataset is created, so if you get a `success`
state of `pending`, please try again in a few seconds.

### Modelling The Open Data Certificate xml files

##### 1: The ODC questionnaire exists in two sections, and accordingly as two files within prototypes directory

The general questionnaire (stored in prototype/translations/certificate.en.xml) containing the questions for General, Technical and Social sections and the legal portion (stored in prototype/jurisdictions/certificate.GB.xml) for questions relating to copyright and IP ownership that differ by country or legal jurisdiction

##### 2: prototype/surveyor.xsl transforms these two XML files into survey/odc_questionnaire.$country_code.rb

the mechanism by which specific country codes and their corresponding language is translated is being refactored at present  see [Surveyor/Translations](#translations) below

##### 3: the surveyor gem parses the odc_questionairre.$COUNTRY_CODE.rb file, and produces the following models

`Survey, SurveySection, Question, QuestionGroup,Answer, Dependency, DependencyCondition.`

which are stored in `app/models`

A `Question` will may have a `Dependency`
the `Dependency` will have_many `DependencyCondition`s which may belong to other `Question`s
the `DependencyCondition`s have one `Question` and one `Answer` and then an `operator` to compare test them against


##### 4: app/SurveysController starts a survey and updates it

##### 5: Test suites exist in

```
vendor/surveyor/gems/surveyor-1.4.0/spec/
test/unit/question_test.rb
test/unit/response_set_test.rb
```

##### Unknowns:

need to inspect surveys/development subdirectory [potential ticket)

### Surveyor

The Open Data Certificate uses [surveyor](https://github.com/NUBIC/surveyor) to generate and display the data questionnaires.
We've changed the look, feel & structure to fit the site and extended it to support certificate levels.

Although all of Surveyor's functionality is supported - much of it isn't incorporated into the initial designs, and so hasn't
been tested to work correctly. Experiments with the demo "kitchen sink survey" illustrate that some of the question types
that Surveyor supports break the CSS, so please beware if extending the current questionnaire with other question types
- they will need to be tested and possibly need CSS/renderer design changes.


#### Deploying questionnaires

Any changed surveys can be generated by running a rake task:

```bash
# build all surveys in ./surveys
rake surveyor:build_changed_surveys

# specify a survey directory
rake surveyor:build_changed_surveys DIR=surveys/development
```

#### Survey versions

When a survey is updated and re-imported, it will be imported as a new version of the survey.

The identity of a survey is judged by the title (the string following `survey` on the first line of the survey dsl).  This is [transformed slightly](https://github.com/NUBIC/surveyor/blob/f90c38ff3ac29e9e9493bd2df3fa718393bd1f85/lib/surveyor/models/survey_methods.rb#L35-L38) from "My awesome title!!1" to "my-awesome-title"

With this in mind, be careful:

* that different survey files have unique names
* that changing the name of the survey might be painful.


#### Surveyor extensions

We've extended surveyor with some attributes for the Open Data Certificate.

##### requirement

A 'Requirement' is a bar that needs to be passed to contribute to attaining a certain level in the questionnaire.
This is not the same as being "required" - which is about whether a question is mandatory to be completed.
For the moment, requirements are stored in the questions database table as labels with a 'requirement' attribute set.

Questions and Answers are associated to requirements by having their 'requirement' attribute set as the same value. Thus; for every label with a requirement set, there should be a question (or an answer) with the same value set.

##### survey

* `:dataset_curator` - Identifies (by its 'reference_identifier' value) which form element should be used to populate the dataset curator field (currently `publisher`).

* `:dataset_title` - Identifies (by its 'reference_identifier' value) which form element should be used to populate the dataset title field (currently `dataTitle`)

* `:description` - Copy to be displayed above the questionnaire

##### section

* `:display_header` - Whether the header should be displayed on the header (defaults to true)

##### question

* `:requirement` - If the question is a Label-type, requirement is the identifier of an improvement that is recommended to meet a certain level.
The value will be stored as `"pilot_1"`, `"pilot_2"`, `"pilot_3"`, `"basic_1"`, `"basic_2"`, etc. With the part before
the underscore representing the level, and everything after the underscore uniquely identifying the requirement.
If the question is a "normal" question (ie: not a label), the requirement attribute is used to identify to the recommended improvement this question satisfies.

* `:required` - Whether or not this question is required/mandatory to be completed (it also has to be triggered in the questionnaire by its dependencies).
Any value in here will make the question mandatory, but it can also be used to identify if it is mandatory for a specific level of certificate attainment
(if this requires different styling in the UI) ie: `:required #=> mandatory for every level`  , `:pilot #=> mandatory for 'pilot' level`

* `:help_text_more_url` - The url to link to at the end of the help text

* `:text_as_statement` - How the text should appear when it's displayed on the certificate (eg. "What is your name?" should read as "Name")

* `:display_on_certificate` - If the question should appear on the certificate

* `:discussion_topic` - Sets the topic (and enables) juvia discussion for this question (accessible by clicking "Ask for help with this question").  The `:help_text` value for this question will appear at the top of the discussion page.

##### answer

* `:requirement` - Identifies the recommended improvement that this answer satisfies.

* `:help_text_more_url` - as above

* `:text_as_statement` - as above

* `:input_type` - alternative input types (eg. url, number, phone)

* `:placeholder` - placeholder text displayed in a field before anything is entered

### Translations

Questionnaires are able to be translated and a user can select the locale when they are filling them out.

To enable this for a questionnaire:

* set any alternative translations files using the `translations` method (eg. `:es => 'translations/my-file.es.yml'`)

In the translation file (eg. surveys/translations/my-file.es.yml)

* set the locale name with `es: Spanish` (where 'es' was the reference given in the survey file)

There is an example of adding a translation on [this gist](https://gist.github.com/benfoxall/c35ad597fd2c2d7fcdc6#file-0002-manually-corrected-translation-yaml-patch)


#### Development things

```bash
# generate a stripped back version of the default survey (GB)
# - makes page loads more bearable in development
rake surveyor:build_changed_survey FILE=surveys/development/odc_GB_stub.rb

# generate development surveys (includes GB stub)
rake surveyor:build_changed_surveys DIR=surveys/development

# run tests on file change
bundle exec guard
```


#### Environment variables

Some environment variables are required for the certificates site, these can be set in a .env file in the root of the project.

```
# A hostname to create links in emails
CERTIFICATE_HOSTNAME="localhost:3000"

# Rackspace credentials for saving certificate dumps
RACKSPACE_USERNAME
RACKSPACE_API_KEY
RACKSPACE_CERTIFICATE_DUMP_CONTAINER

# Juvia details to allow commenting
JUVIA_BASE_URL
CERTIFICATE_JUVIA_SITE_KEY

# Sending error reports to airbrake
AIRBRAKE_CERTIFICATE_KEY

# Enable footnotes for debugging info
ENABLE_FOOTNOTES=true
```

#### Admin functions

To mark a user as being an admin use the rails console to set the `admin` field to true. The easiest way to find the ID is to look on the URL of their account page.

    User.find(<id>).update_attributes(admin: true)

Admins are able to block a dataset from displaying on the public /datasets page by visiting the dataset and toggling the visibility at the top of the page.

Removed datasets are listed at `/datasets/admin` (only accessible by admin users).


#### Changing surveys

To change surveys, you'll need Saxon installed. On a Mac, this is as simple as running:

```bash
brew install saxon
```

You can then change the `prototype/survey.xsl` file and run:

```bash
saxon -s:prototype/jurisdictions/ -xsl:prototype/surveyor.xsl -o:prototype/temp/
```


### Autocompletion

The survey attempts to fetch answers from the documentation URL and fill them into the questionnaire. These answers are marked as autocompleted.

Some examples of URLS that can be autocompleted:

- http://data.gov.uk/dataset/overseas_travel_and_tourism
- http://data.gov.uk/dataset/apprenticeship-success-rates-in-england-2011-2012
- http://data.ordnancesurvey.co.uk/datasets/50k-gazetteer
- http://data.ordnancesurvey.co.uk/datasets/boundary-line
- http://smtm.labs.theodi.org/download/


#### Surveyor validation

A breakdown of the validation states that exist in the survey:

- `no-response` a field which has not been filled in, white
- `ok` a completed field (light green)
- `error` a mandatory field which hasn't been filled in, shown after trying to finish the survey (light red)
- `url-verified` a URL field which has been verified (light green with message)
- `autocompleted` an autocompleted field (light green with message)
- `autocompleted-changed` an autocompleted, but changed field (light orange with message and explanation box)
- `autocompleted-explained` an autocompleted, changed field which has an explanation (light green with message and explanation box)
- `url-warning` a URL field which has failed verification (light orange with message and explanation box)
- `autocompleted-url-warning` a URL field which has been autocompleted AND failed verification (light orange with message and explanation box)
- `url-explained` a URL field which has failed verification but has an explanation (light green with message and explanation box)
- `metadata-missing` the documentation metadata field, which has values selected incorrectly (light orange with message and explanation box)

#### Additional documentation

[App approach document](https://docs.google.com/a/whiteoctober.co.uk/document/d/1Ot91x1enq9TW7YKpePytE-wA0r8l9dmNQLVi16ph-zg/edit#)

The original prototype has been moved to [/prototype](https://github.com/theodi/open-data-certificate/tree/master/prototype).

#### Flowchart

http://localhost:3000/flowchart
files responsible:
```ruby
lib>flow.rb
app>controllers>flowcharts_controller.rb
app>views>flowcharts/.
```
you'll want to have open
prototype/translation/certificate.en.xml & prototype/jurisdictions/certificate.GB.xml

rendering flow =
```
show
^~> _question
___^~> _answer
______^~> _dependency
_________^~> _answer

// this effectively functions as a foreach loop

foreach(question_element in @questions hash)
    # passes a hash
    foreach(answer in answers hash*)
        #*where `answers` is extracted from question_element as a key=>value element
        PartialDependency(question_element, question_element_index, answer.key, answer.value)
           # A Hash is retrieved from @dependencies instance hash and assigned to dependency (local var)
           # answer[:dependency] and dependency[:label] are the values printed to screen in varying outputs

```

each of the partials render text in the markdown format which https://github.com/knsv/mermaid stipulates

Intern Suggestions:

Clearer explanation.
Make calls between dependency and answer clearer.
List of all possible answer dependencies.
Test for dependencies inside and outside answer

Flow pseudocode:

  -- Question

  if the question has no answers and there exists a next question
    convert question id and label into readable string ...
  else if the question has answers, for each answer

    -- Answer

    if there is no answer dependency and there is a next question
      convert question id and label into readable string ...
    else if there is an answer dependency

      -- Dependency

      dependency = returns more information about dependency of a given answer as a hash
      if there are no answers for that dependency
        convert question id and label into readable string ...
        if there is a next question
          render question/answer/dependency
        else render end block
      else
        render question/answer/dependency
        if dependency prerequisites are <= 1 or (dependency is one of ["timeSensitive","privacyImpactAssessmentExists"] & dependency has 2 prerequisites)
          for each dependency answer
            render answer
            add it to @deps
        else
          destroy first prerequisite of dependency

    else
      Render end block
