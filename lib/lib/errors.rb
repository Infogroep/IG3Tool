module Ig3tool

	class IG3Error < Exception
	end

	class Token < IG3Error
	end

	class ProductNotFound < IG3Error
	end
	
  class PermissionDenied < IG3Error
	end

	class NeedDebugger < IG3Error
	end

	class NotADebugger < IG3Error
	end

	class NotAMember < IG3Error
	end

	class Needed < IG3Error
	end

	class NotFound < IG3Error
	end

	class WrongRequestType < IG3Error
	end

	class InternalError < IG3Error
	end



	# PRINTING

	class PrintBackend < IG3Error
	end

	class NoPrintAccount < IG3Error
	end

	class NotEnoughCredit < IG3Error
	end

	class WrongPrintlogType < IG3Error
	end

	class SaveFailed < IG3Error
	end

	class AliasNotFound < IG3Error
	end

	class TransactionNotFound < IG3Error
	end

	class PrintUserNotFound < IG3Error
	end

	# INTERNE

	class TransactionLogFailed < IG3Error
	end

	class NoPositiveAmount < IG3Error
	end

	class TransactionFailed < IG3Error
	end

	class SaldoNotZero < IG3Error
	end

	class Afgesloten < IG3Error
	end

	# BIB

	class StillHaveLoans < IG3Error
	end

	class BibSectionNotFound < IG3Error
	end

	class InvalidISBN < IG3Error
	end

	class BookNotAvaible < IG3Error
	end
end
