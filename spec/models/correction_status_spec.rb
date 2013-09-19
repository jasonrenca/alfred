require 'spec_helper'

describe CorrectionStatus do
  describe 'corrections_status_for_teacher' do
    let(:teacher) { double(:id => 1234) }

    it "should use teacher's ID in DB query" do
      repository(:default).adapter
        .should_receive(:select)
        .with("SELECT DISTINCT s.account_id, s.assignment_id  FROM corrections c INNER JOIN solutions s ON s.id = c.solution_id WHERE c.teacher_id = #{teacher.id}")
        .and_return([])

      CorrectionStatus.corrections_status_for_teacher(teacher)
    end

    context "CorrectionStatus creation based on solution" do
      let(:student) { double(:id => 99, :full_name => 'Juan Perez', :buid => '1234567') }
      let(:assignment) { double(:id => 1, :name => 'TP') }
      let(:correction) { double(:id => 500, :status => :correction_passed, :grade => 10.0, :teacher => teacher) }
      let(:solution) { double(:id => 1000, :assignment => assignment, :account => student, :test_result => 'passed') }

      it "should use last solution for creating CorrectionStatus" do
        repository(:default).adapter.stub(:select).and_return([ double(:account_id => student.id, :assignment_id => assignment.id) ])
        Solution.should_receive(:last).with(:account_id => student.id, :assignment_id => assignment.id, :order => :created_at).and_return(solution)
        solution.stub(:correction).and_return(correction)

        corrections_status = CorrectionStatus.corrections_status_for_teacher(teacher)

        corrections_status.count.should == 1
        corrections_status[0].assignment_id.should == assignment.id
        corrections_status[0].assignment_name.should == assignment.name
        corrections_status[0].student_id.should == student.id
        corrections_status[0].student_full_name.should == student.full_name
        corrections_status[0].student_buid.should == student.buid
        corrections_status[0].solution_id.should == solution.id
        corrections_status[0].solution_test_result.should == solution.test_result
        corrections_status[0].correction_id.should == solution.correction.id
        corrections_status[0].status.should == solution.correction.status
        corrections_status[0].grade.should == solution.correction.grade
      end

      it "should create CorrectionStatus even if last solution has not correction associated" do
        repository(:default).adapter.stub(:select).and_return([ double(:account_id => student.id, :assignment_id => assignment.id) ])
        Solution.should_receive(:last).with(:account_id => student.id, :assignment_id => assignment.id, :order => :created_at).and_return(solution)
        solution.stub(:correction).and_return(nil)

        corrections_status = CorrectionStatus.corrections_status_for_teacher(teacher)

        corrections_status.count.should == 1
        corrections_status[0].assignment_id.should == assignment.id
        corrections_status[0].assignment_name.should == assignment.name
        corrections_status[0].student_id.should == student.id
        corrections_status[0].student_full_name.should == student.full_name
        corrections_status[0].student_buid.should == student.buid
        corrections_status[0].solution_id.should == solution.id
        corrections_status[0].solution_test_result.should == solution.test_result
        corrections_status[0].correction_id.should be_nil
        corrections_status[0].status.should == :correction_pending
        corrections_status[0].grade.should be_nil
      end

      it "should create CorrectionStatus for all assigned corrections" do
        student2 = double(:id => 100, :full_name => 'Jose Rodriguez', :buid => '7654321')
        assignment2 = double(:id => 2, :name => 'TP 2')
        correction2 = double(:id => 600, :status => :correction_failed, :grade => 2.0, :teacher => teacher)
        solution2 = double(:id => 2000, :assignment => assignment2, :account => student2, :test_result => 'passed', :correction => correction2)
        repository(:default).adapter.stub(:select).and_return([ double(:account_id => student.id, :assignment_id => assignment.id), double(:account_id => student2.id, :assignment_id => assignment2.id) ])
        Solution.should_receive(:last).with(:account_id => student.id, :assignment_id => assignment.id, :order => :created_at).and_return(solution)
        Solution.should_receive(:last).with(:account_id => student2.id, :assignment_id => assignment2.id, :order => :created_at).and_return(solution2)
        solution.stub(:correction).and_return(nil)

        corrections_status = CorrectionStatus.corrections_status_for_teacher(teacher)

        corrections_status.count.should == 2
        corrections_status[0].assignment_id.should == assignment.id
        corrections_status[0].assignment_name.should == assignment.name
        corrections_status[0].student_id.should == student.id
        corrections_status[0].student_full_name.should == student.full_name
        corrections_status[0].student_buid.should == student.buid
        corrections_status[0].solution_id.should == solution.id
        corrections_status[0].solution_test_result.should == solution.test_result
        corrections_status[0].correction_id.should be_nil
        corrections_status[0].status.should == :correction_pending
        corrections_status[0].grade.should be_nil
        corrections_status[1].assignment_id.should == assignment2.id
        corrections_status[1].assignment_name.should == assignment2.name
        corrections_status[1].student_id.should == student2.id
        corrections_status[1].student_full_name.should == student2.full_name
        corrections_status[1].student_buid.should == student2.buid
        corrections_status[1].solution_id.should == solution2.id
        corrections_status[1].solution_test_result.should == solution2.test_result
        corrections_status[1].correction_id.should == solution2.correction.id
        corrections_status[1].status.should == :correction_failed
        corrections_status[1].grade.should == 2.0
      end
    end
  end
end