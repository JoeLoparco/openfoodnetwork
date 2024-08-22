# frozen_string_literal: true

require "system_helper"

RSpec.describe "Orders And Distributors" do
  include AuthenticationHelper
  include WebHelper
  include ReportsHelper

  describe "Orders And Distributors" do
    let!(:distributor) { create(:distributor_enterprise, name: "By Bike") }
    let!(:distributor2) { create(:distributor_enterprise, name: "By Moto") }
    let!(:completed_at) { Time.zone.now.to_fs(:db) }

    let!(:order) {
      create(:order_ready_to_ship, distributor_id: distributor.id, completed_at:)
    }
    let!(:order2) {
      create(:order_ready_to_ship, distributor_id: distributor2.id, completed_at:)
    }

    context "as an enterprise user" do
      let(:header) {
        ["Order date", "Order Id", "Customer Name", "Customer Email", "Customer Phone",
         "Customer City", "SKU", "Item name", "Variant", "Quantity", "Max Quantity",
         "Cost", "Shipping Cost", "Payment Method", "Distributor", "Distributor address",
         "Distributor city", "Distributor postcode", "Shipping Method",
         "Shipping instructions"]
      }
      let(:line_item1) {
        [completed_at, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
         "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check",
         "By Bike", "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
      }
      let(:line_item2) {
        [completed_at, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
         "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check",
         "By Bike", "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
      }
      let(:line_item3) {
        [completed_at.to_s, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
         "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check",
         "By Bike", "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
      }
      let(:line_item4) {
        [completed_at.to_s, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
         "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check",
         "By Bike", "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
      }
      let(:line_item5) {
        [completed_at.to_s, order.id, "John Doe", order.email, "123-456-7890", "Herndon",
         "ABC", Spree::Product.first.name.to_s, "1g", "1", "none", "10.0", "none", "Check",
         "By Bike", "10 Lovely Street", "Herndon", "20170", "UPS Ground", "none"].join(" ")
      }

      before do
        login_as(distributor.owner)
        visit admin_reports_path
        click_link "Orders And Distributors"
        run_report
      end

      it "generates the report" do
        rows = find("table.report__table").all("thead tr")
        table_headers = rows.map { |r| r.all("th").map { |c| c.text.strip } }

        expect(table_headers).to eq([header])

        expect(all('table.report__table tbody tr').count).to eq(
          Spree::LineItem.where(
            order_id: order.id # Total rows should equal nr. of line items, per order
          ).count
        )

        # displays only orders from the hub it is managing
        expect(page).to have_content(distributor.name), count: 5

        # only sees line items from orders it manages
        expect(page).not_to have_content(distributor2.name)

        # displayes table contents correctly, per line item
        table = page.find("table.report__table tbody")
        expect(table).to have_content(line_item1)
        expect(table).to have_content(line_item2)
        expect(table).to have_content(line_item3)
        expect(table).to have_content(line_item4)
        expect(table).to have_content(line_item5)
      end

      describe "downloading the report" do
        shared_examples "reports generated as" do |output_type, extension|
          context output_type.to_s do
            it "downloads the #{output_type} file" do
              select output_type, from: "report_format"

              expect { generate_report }.to change { downloaded_filenames.length }.from(0).to(1)

              expect(downloaded_filename).to match(/.*\.#{extension}/)

              downloaded_file_txt = load_file_txt(extension, downloaded_filename)

              expect(downloaded_file_txt).to have_text header.join(" ")
              expect(downloaded_file_txt).to have_text(
                "By Bike 10 Lovely Street Herndon 20170 UPS Ground", count: 5
              )
            end
          end
        end

        it_behaves_like "reports generated as", "CSV", "csv"
        it_behaves_like "reports generated as", "Spreadsheet", "xlsx"
      end
    end

    context "as admin" do
      before do
        login_as_admin
        visit admin_reports_path
        click_link "Orders And Distributors"
      end

      context "with two orders on the same day at different times" do
        let(:completed_at1) { 1500.hours.ago } # 1500 hours in the past
        let(:completed_at2) { 1700.hours.ago } # 1700 hours in the past
        let(:datetime_start1) { 1600.hours.ago } # 1600 hours in the past
        let(:datetime_start2) { 1800.hours.ago } # 1600 hours in the past
        let(:datetime_end) { 1400.hours.ago } # 1400 hours in the past
        let!(:order3) {
          create(:order_ready_to_ship, distributor_id: distributor.id, completed_at: completed_at1)
        }
        let!(:order4) {
          create(:order_ready_to_ship, distributor_id: distributor.id, completed_at: completed_at2)
        }

        context "applying filters" do
          it "displays line items from the correct distributors" do
            # for one distributor
            select2_select distributor.name, from: "q_distributor_id_in"
            run_report
            expect(page).to have_content(distributor.name), count: 15

            clear_select2("#s2id_q_distributor_id_in")

            # for another distributor
            select2_select distributor2.name, from: "q_distributor_id_in"
            run_report
            expect(page).to have_content(distributor2.name), count: 5
          end
        end
      end
    end
  end
end
