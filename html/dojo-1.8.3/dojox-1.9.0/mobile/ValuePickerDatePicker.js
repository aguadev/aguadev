define([
	"dojo/_base/declare",
	"dojo/dom-class",
	"./_DatePickerMixin",
	"./ValuePicker",
	"./ValuePickerSlot"
], function(declare, domClass, DatePickerMixin, ValuePicker, ValuePickerSlot){

	// module:
	//		dojox/mobile/ValuePickerDatePicker

	return declare("dojox.mobile.ValuePickerDatePicker", [ValuePicker, DatePickerMixin], {
		// summary:
		//		A ValuePicker-based date picker widget.
		// description:
		//		ValuePickerDatePicker is a date picker widget. It is a subclass of
		//		dojox/mobile/ValuePicker. It has 3 slots: day, month and year.
		
		// readOnly: [const] Boolean
		//		If true, slot input fields are read-only. Only the plus and
		//		minus buttons can be used to change the values.
		//		Note that changing the value of the property after the widget 
		//		creation has no effect.
		readOnly: false,

		slotClasses: [
			ValuePickerSlot,
			ValuePickerSlot,
			ValuePickerSlot
		],

		slotProps: [
			{labelFrom:1970, labelTo:2038, style:{width:"87px"}},
			{style:{width:"72px"}},
			{style:{width:"72px"}}
		],

		buildRendering: function(){
			var p = this.slotProps;
			p[0].readOnly = p[1].readOnly = p[2].readOnly = this.readOnly;
			this.initSlots();
			this.inherited(arguments);
			domClass.add(this.domNode, "mblValuePickerDatePicker");
			this._conn = [
				this.connect(this.slots[0], "_spinToValue", "_onYearSet"),
				this.connect(this.slots[1], "_spinToValue", "_onMonthSet"),
				this.connect(this.slots[2], "_spinToValue", "_onDaySet")
			];
		},

		disableValues: function(/*Number*/daysInMonth){
			// summary:
			//		Disables the end days of the month to match the specified
			//		number of days of the month.
			var items = this.slots[2].items;
			if(this._tail){
				this.slots[2].items = items = items.concat(this._tail);
			}
			this._tail = items.slice(daysInMonth);
			items.splice(daysInMonth);
		}
	});
});
