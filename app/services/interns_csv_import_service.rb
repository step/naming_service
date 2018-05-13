require 'csv'

class InternsCsvImportService

  def initialize(file)
    @filename = file.original_filename
    @rows = get_csv_entries(file)
    # @rows = get_rows_hash(file)
  end

  def import
    return import_summary_on_invalid_headers(@filename, @rows.length) if invalid_headers?

    interns = @rows.map {|row|
      intern = Intern.new(transform_to_interns_params(row))
      intern.save
      {data: row, errors: intern.errors.count > 0 ? intern.errors.full_messages : []}
    }
    import_results(@filename, interns)
  end

  private

  def get_csv_entries file
    CSV.read(file.path, headers: true, :header_converters => :symbol).entries
  end

  def transform_to_interns_params(r)
    row = r.to_h
    intern_params = row.slice(:emp_id, :display_name, :first_name, :last_name, :dob, :gender)
    batch = Batch.find_by(name: row[:batch])
    intern_params[:batch_id] = batch.present? ? batch.id : nil
    intern_params[:emails_attributes] = [
        {:category => 'Personal', :address => row[:personal_email]},
        {:category => 'ThoughtWorks', :address => row[:thoughtworks_email]}
    ]
    intern_params[:github_attributes] = github_attributes(row[:github_username])
    intern_params[:slack_attributes] = slack_attributes(row[:slack_username])
    intern_params[:dropbox_attributes] = dropbox_attributes(row[:dropbox_username])
    intern_params
  end

  def github_attributes(username)
    {username: username}
  end

  def slack_attributes(username)
    {username: username}
  end

  def dropbox_attributes(username)
    {username: username}
  end

  def import_summary_on_invalid_headers(filename, total_rows)
    {
        filename: filename,
        errors: ['Invalid headers'],
        total: total_rows,
        failed: total_rows,
        success: 0,
        invalid_rows: []
    }
  end

  def import_results(filename, all_rows)
    invalid_rows = select_invalid_rows_from all_rows
    {
        filename: filename,
        errors: [],
        total: all_rows.length,
        failed: invalid_rows.length,
        success: (all_rows.length - invalid_rows.length),
        invalid_rows: invalid_rows
    }
  end

  def select_invalid_rows_from rows
    rows.select {|row| row[:errors].length > 0}
  end

  def invalid_headers?
    false
  end

end