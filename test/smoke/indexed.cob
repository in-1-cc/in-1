identification division.
program-id. indexed-smoke.
environment division.
input-output section.
file-control.
    select test-file assign to "records.db"
        organization is indexed
        access mode is random
        record key is record-id
        file status is record-status.
data division.
file section.
fd test-file.
01 record-data.
    02 record-id pic 9(4).
    02 record-text pic x(16).
working-storage section.
01 record-status pic xx.
procedure division.
    open output test-file
    if record-status not = "00" move 1 to return-code goback end-if
    move 1 to record-id
    move "in-1 smoke" to record-text
    write record-data
    if record-status not = "00" move 2 to return-code goback end-if
    close test-file
    open input test-file
    if record-status not = "00" move 3 to return-code goback end-if
    move 1 to record-id
    read test-file
    if record-status not = "00" move 4 to return-code goback end-if
    if record-text not = "in-1 smoke" move 5 to return-code goback end-if
    close test-file
    display record-text
    move 0 to return-code
    goback.
