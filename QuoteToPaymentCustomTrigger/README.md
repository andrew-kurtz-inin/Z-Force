> Copyright (c) 2012 Zuora, Inc.
> 
> Permission is hereby granted, free of
> charge, to any person obtaining a copy
> of  this software and associated
> documentation files (the "Software"),
> to use copy,  modify, merge, publish
> the Software and to distribute, and
> sublicense copies of  the Software,
> provided no fee is charged for the
> Software.  In addition the rights
> specified above are conditioned upon
> the following: The above copyright
> notice and this permission notice
> shall be included in all copies or
> substantial portions of the Software.
> Zuora, Inc. or any other trademarks of
> Zuora, Inc.  may not be used to
> endorse or promote products derived
> from this Software without specific
> prior written permission from Zuora,
> Inc. THE SOFTWARE IS PROVIDED "AS IS",
> WITHOUT WARRANTY OF ANY KIND, EXPRESS
> OR IMPLIED, INCLUDING BUT NOT LIMITED
> TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND
> NON-INFRINGEMENT. IN NO EVENT SHALL
> ZUORA, INC. BE LIABLE FOR ANY DIRECT,
> INDIRECT OR CONSEQUENTIAL DAMAGES
> (INCLUDING, BUT NOT LIMITED TO,
> PROCUREMENT OF SUBSTITUTE GOODS OR
> SERVICES; LOSS OF USE, DATA, OR
> PROFITS; OR BUSINESS INTERRUPTION)
> HOWEVER CAUSED AND ON ANY THEORY OF
> LIABILITY, WHETHER IN CONTRACT, STRICT
> LIABILITY, OR TORT (INCLUDING
> NEGLIGENCE OR OTHERWISE) ARISING IN
> ANY WAY OUT OF THE USE OF THIS
> SOFTWARE, EVEN IF ADVISED OF THE
> POSSIBILITY OF SUCH DAMAGE.

**Zuora Z-Force Sample Code Package: Quote-to-Payment Custom Trigger Sample**
--

**Introduction**
--

This Z-Force Sample Code Package provides a reference implementation of the BeforeInsert Trigger on "Quote Processing Data" object, which is part of Z-Force Quotes feature "Mass Quote-to-Payment Processing".

**Pre-Requisites**
--

* The Z-Force Sample Code Suite includes a set of unmanaged packages that depend on the following Z-Force managed packages:
  * Z-Force Quotes Version 5.6

**Package Contents**
--

This package contains one BeforeInsertTrigger of the "Quote Processing Data" object in Z-Force Quotes version 5.6 and above.

This trigger (QuoteValidationTrigger) contains the following business logic:
* Gathers all quote numbers from the triggered records to be used. Default these Quote Processing Data records to be valid.
* If the QuoteNumber of the corresponding QuoteProcessingData is blank, mark the Quote Processing Data as Invalid.
* Retrieve quotes based on the QuoteNumber in the QuoteProcessingData records
  * If the quote of the corresponding QuoteNumber does not exist, mark the QuoteProcessingData as invalid.
  * If the PaymentAmount of the QuoteProcessingData record is not equal to the quote's total amount, mark the QuoteProcessingData as invalid.
  * If the EffectiveDate of the QuoteProcessingData is a not-null value, set the Start Date of the corresponding quote to the EffectiveDate+1.

