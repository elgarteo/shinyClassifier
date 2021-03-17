# shinyClassifier

This Shiny app is a multi-user image/text classification tool designed 
for any scenario that involves a bunch of human coders classifying a bunch of 
text or images into pre-specified categories. All it takes is a YAML config file
and a CSV file to set up an online multi-user classification system.

## Prerequisite

If you are deploying this dashboard on your own Shiny Server, please
make sure the following packages are installed:

-   `shinydashboard`
-   `shinyjs`
-   `shinymanager`
-   `DT`
-   `purrr`
-   `magrittr`

You also need `yaml` installed for the configuration process.

## Configure

This app is configured with two files: `config.yaml` and `data.csv`.

### `config.yaml`

All the basic configurations of your classifier go here. The file itself
is pretty self-explanatory so this section only focuses on setting up
the users and questions.

You need to specify the username and password for each of the users 
(aka human coders) involved in the classification. You are strongly recommended
to also set up an administrator account so that you can keep track of 
everyone’s progress as well as to manage the accounts later on.

User credentials can be specified in the following format:

``` yaml
user:
- user: admin
  password: admin
  admin: true
- user: test
  password: test
  admin: false
```

The user credentials here will be stored in a SQLite database with the
passwords hashed. For security concern, you may want to assign dummy
passwords in the config file and then change them in the admin console later,
where you can also force users to change their passwords upon the first log
in.

This app supports the presentation of multiple mutually exclusive questions 
on the same content. Say your goal is to sort out cat images, and if so what is
the colour of the cat. You can then specify the questions as follows:

``` yaml
question:
  - text: Is there a cat?
    value: cat
    choice:
      - name: "Yes"
        value: 1
      - name: "No"
        value: 0
  - text: If there is, what is its colour?
    value: color
    choice:
      - name: Not Applicable
        value: NA
      - name: Black
        value: black
      - name: Cinnamon
        value: cinnamon
      - name: Orange
        value: orange
      - name: Gray
        value: gray
```

The `text` and `name` entries are what the users will see in the
interface. The `value` entries are the variable names of your data. The usual
variable naming conventions for R apply. You can also specify JavaScript key code
of the short cut key for quick selection in the `keycode` entry for each choice.
In the example above, the box for Gray will be checked if the user presses the
`4` key on the keyboard. 

You can specify the shortcut keys for each choice of the questions and for 
navigation purpose as follow:

```yaml
question:
  - text: Is there a cat?
    value: cat
    choice:
      - name: "Yes"
        value: 1
        keycode: 89
      - name: "No"
        value: 0
        keycode: 78
...
shortcut: 
  - action: submit
    keycode: 13
  - action: prev
    keycode: 37
  - action: next
    keycode: 39
```

The `keycode` entry accepts JavaScript key code. In the example above, pressing
the `Y` key on the keyboard will check the choice "Yes", and pressing the `Enter`
key will submit the checked answers.

### `data.csv`

This CSV files should have a column with the name `data` containing the
text or links of the images to-be-classified.

## Initialize

Place `config.yaml` and `data.csv` in the root directory and run:

``` r
source("initilize.R")
initialize_app()
```

This function parses the `config.yaml` file and creates a `user.sqlite`
storing the user credentials and a `config.rda` containing the
configurations of your classification task.

Afterwards, run:

``` r
prep_data()
```

This function reads `data.csv` and then randomly and evenly assign contents to
each of the users (excluding admin accounts). Each user gets its own
`data_<username>.rds` file with the contents they are tasked to classify.

Note that at this stage all the coders involved should have had their accounts
set up. Any new user added after this stage will not be assigned with any task,
unless `prep_data()` is run again (which will reset the progress of all users).

In the event where even distribution is not possible, the first few
users will be assigned one extra entry. For example, if there are
4,000 images to be split within 3 coders, coder A and B will get 1,667
images while coder C will get 1,666 images.

If you need all users to work on the same set of content (e.g. for inter-coder 
reliability test), run:

``` r
prep_data(dist = FALSE)
```

## Deploy

This app can be deployed on a Shiny Server after running the two initialization 
functions. You can log into the admin account to check the progress of each
individual user. To change user account settings, click on the round button 
on the bottom right to access the _Administrator mode_ powered 
by `shinymanager`.

The classification results of each user are stored in their respective
`data_<username>.rds` files. You can also download the data in CSV format
in the admin console. Unclassified entries are marked as `NA` in the data and 
shown as empty cells in the admin console. If you’re hosting this app on your
own Shiny Server, make sure Shiny has the permission to write into the 
directory.

In addition to the defined questions, a check box is presented in every
entry for the users to mark any potentially disputable case. Entries marked
as such will have the column `problem` defined as `TRUE` in the classification
results.

## Warning

This application is not designed to handle simultaneous login of the <u>same</u> 
user. Doing so may result in data loss.
