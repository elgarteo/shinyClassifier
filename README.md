
<!-- README.md is generated from README.Rmd. Please edit that file -->

shinyClassifier
===============

This Shiny application is a template of a multi-user image/text
classification tool designed for any scenario that involves a bunch of
human coders classifying a bunch of text or images. All it takes is a
YAML config file and a CSV file with the content to-be-classified to
construct an online multi-user classification system.

Prerequisite
------------

If you are deploying this dashboard on your own Shiny Server, please
make sure the following packages are installed:

-   `shiny` (obviously)
-   `shinydashboard`
-   `shinyjs`
-   `shinymanager`
-   `DT`
-   `purrr`
-   `magrittr`

Configure
---------

You need to have two files ready: `config.yaml` and `data.csv`.

### `config.yaml`

All the basic configurations of your project goes here. The file itself
is pretty self-explanatory so this section only focuses on setting up
the users and questions.

For user details, you need to specify the username and password for each
of the users (aka human coders) involved in the project. You are
strongly recommended to also set up an administrator account to keep
track of the progress as well as to mange the users later on.

    user:
      - user: admin
        password: admin
        admin: true
      - user: test
        password: test
        admin: false

Please note that you need to have all the users set up at this stage. It
is problematic to add any new user in the middle of the project period
since the distribution of content to each user happens at the
initialization stage.

The user details here will be stored in a SQLite database with the
passwords hashed. For security concern, you may want to assign dummy
passwords here and then change the passwords in the admin console, where
you can also force users to change their passwords upon the first log
in.

Say your project is to find out whether an image has a human in it, and
if so what is the gender, the questions can be set up as follows:

    question:
      - text: Is there a human?
        value: human
        choice:
          - name: "Yes"
            value: 1
          - name: "No"
            value: 0
      - text: If there is, what is the gender?
        value: gender
        choice:
          - name: Not Applicable
            value: NA
          - name: Male
            value: M
          - name: Female
            value: F

The `text` and `name` entries are what the coders will see in the
interface. The `value` entries are the variable names of your data. As
with all variable names in programming, you should avoid space and
problematic symbols.

### `data.csv`

This CSV files should contain a column with name `data` containing the
text or links of the images to-be-classified.

Initialization
--------------

Place `config.yaml` and `data.csv` in the root directory and run:

    source("initilize.R")
    initialize_app()

This will parse the `config.yaml` file and create a `user.sqlite`
storing the user details and a `config.rda` containing the
configurations of your project.

Afterwards, run:

    prep_data()

This will read `data.csv` and randomly and equally assign contents to
each of the users (excluding admin accounts). Each user gets its own
`data_<username>.rds` file with the content they are working on.

In the event where even distribution is not possible, the first few
users will get one extra assigned content. For example, if there are
4000 images to be split within 3 coders, coder A and B will get 1667
images while coder C will get 1666 images.

If you need all users to work on the same set of content (e.g. for
inter-coder reliability test), run:

    prep_data(dist = FALSE)

Using
-----

Afterwards, the app is ready to be deployed. You can log into the admin
account to check the progress of each individual user. The
classification results of each user are stored in their respective
`data_<username>.rds` files.